<script>
import { GlTokenSelector, GlLabel, GlSkeletonLoader } from '@gitlab/ui';
import { debounce, uniqueId, without } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Tracking from '~/tracking';
import labelSearchQuery from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import LabelItem from '~/sidebar/components/labels/labels_select_widget/label_item.vue';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { isScopedLabel } from '~/lib/utils/common_utils';
import workItemLabelsSubscription from 'ee_else_ce/work_items/graphql/work_item_labels.subscription.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';

import {
  i18n,
  I18N_WORK_ITEM_ERROR_FETCHING_LABELS,
  TRACKING_CATEGORY_SHOW,
  WIDGET_TYPE_LABELS,
} from '../constants';

function isTokenSelectorElement(el) {
  return (
    el?.classList.contains('gl-label-close') ||
    el?.classList.contains('dropdown-item') ||
    // TODO: replace this logic when we have a class added to clear-all button in GitLab UI
    (el?.classList.contains('gl-button') &&
      el?.closest('.form-control')?.classList.contains('gl-token-selector'))
  );
}

function addClass(el) {
  return {
    ...el,
    class: 'gl-bg-transparent',
  };
}

export default {
  components: {
    GlTokenSelector,
    GlLabel,
    GlSkeletonLoader,
    LabelItem,
  },
  mixins: [Tracking.mixin()],
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
      searchStarted: false,
      localLabels: [],
      searchKey: '',
      searchLabels: [],
      addLabelIds: [],
      removeLabelIds: [],
    };
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace.workItems.nodes[0];
      },
      skip() {
        return !this.workItemIid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
      subscribeToMore: {
        document: workItemLabelsSubscription,
        variables() {
          return {
            issuableId: this.workItemId,
          };
        },
      },
    },
    searchLabels: {
      query: labelSearchQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.searchKey,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace?.labels?.nodes.map((node) => addClass({ ...node, ...node.label }));
      },
      error() {
        this.$emit('error', I18N_WORK_ITEM_ERROR_FETCHING_LABELS);
      },
    },
  },
  computed: {
    labelsTitleId() {
      return uniqueId('labels-title-');
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_labels',
        property: `type_${this.workItem.workItemType?.name}`,
      };
    },
    allowScopedLabels() {
      return this.labelsWidget?.allowsScopedLabels;
    },
    containerClass() {
      return !this.isEditing ? 'gl-shadow-none!' : '';
    },
    isLoading() {
      return this.$apollo.queries.searchLabels.loading;
    },
    labelsWidget() {
      return this.workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_LABELS);
    },
    labels() {
      return this.labelsWidget?.labels?.nodes || [];
    },
  },
  watch: {
    labels(newVal) {
      if (!this.isEditing) {
        // remove labels that aren't in list from server
        this.localLabels = this.localLabels.filter((label) =>
          newVal.find((l) => l.id === label.id),
        );

        // add any that we don't have to the end
        const labelsToAdd = newVal
          .map(addClass)
          .filter((label) => !this.localLabels.find((l) => l.id === label.id));

        this.localLabels = this.localLabels.concat(labelsToAdd);
      }
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    getId(id) {
      return getIdFromGraphQLId(id);
    },
    removeLabel({ id }) {
      this.localLabels = this.localLabels.filter((label) => label.id !== id);
      this.removeLabelIds.push(id);
      this.setLabels();
    },
    async setLabels() {
      this.searchKey = '';
      this.isEditing = false;

      if (this.addLabelIds.length === 0 && this.removeLabelIds.length === 0) return;

      try {
        const {
          data: {
            workItemUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              labelsWidget: {
                addLabelIds: this.addLabelIds,
                removeLabelIds: this.removeLabelIds,
              },
            },
          },
        });

        if (errors.length > 0) {
          this.throwUpdateError();
          return;
        }

        this.addLabelIds = [];
        this.removeLabelIds = [];

        this.track('updated_labels');
      } catch {
        this.throwUpdateError();
      }
    },
    throwUpdateError() {
      this.$emit('error', i18n.updateError);
      // If mutation is rejected, we're rolling back to initial state
      this.localLabels = this.labels.map(addClass);
      this.addLabelIds = [];
      this.removeLabelIds = [];
    },
    handleBlur(event) {
      if (isTokenSelectorElement(event.relatedTarget) || !this.isEditing) return;
      this.setLabels();
    },
    handleFocus() {
      this.isEditing = true;
      this.searchStarted = true;
    },
    async focusTokenSelector(labels) {
      const labelsToAdd = without(labels, ...this.localLabels);
      const labelIdsToAdd = labelsToAdd.map((label) => label.id);
      const labelIdsToRemove = without(this.localLabels, ...labels).map((label) => label.id);

      if (labelIdsToAdd.length > 0) {
        this.addLabelIds.push(...labelIdsToAdd);
      }

      if (labelIdsToRemove.length > 0) {
        this.removeLabelIds.push(...labelIdsToRemove);
      }

      if (labels.length === 0) {
        this.localLabels = [];
      } else {
        this.localLabels = this.localLabels.concat(labelsToAdd);
      }

      this.handleFocus();
      await this.$nextTick();
      this.$refs.tokenSelector.focusTextInput();
    },
    handleMouseOver() {
      this.timeout = setTimeout(() => {
        this.searchStarted = true;
      }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    },
    handleMouseOut() {
      clearTimeout(this.timeout);
    },
    setSearchKey(value) {
      this.searchKey = value;
    },
    scopedLabel(label) {
      return this.allowScopedLabels && isScopedLabel(label);
    },
  },
};
</script>

<template>
  <div class="form-row gl-mb-5 work-item-labels gl-relative gl-flex-nowrap">
    <span
      :id="labelsTitleId"
      class="gl-font-weight-bold gl-mt-2 col-lg-2 col-3 gl-pt-2 min-w-fit-content gl-overflow-wrap-break"
      data-testid="labels-title"
      >{{ __('Labels') }}</span
    >
    <gl-token-selector
      ref="tokenSelector"
      :selected-tokens="localLabels"
      :aria-labelledby="labelsTitleId"
      :container-class="containerClass"
      :dropdown-items="searchLabels"
      :loading="isLoading"
      :view-only="!canUpdate"
      :allow-clear-all="isEditing"
      class="gl-flex-grow-1 gl-border gl-border-white gl-rounded-base col-9 gl-align-self-start gl-px-0! gl-mx-2!"
      data-testid="work-item-labels-input"
      :class="{ 'gl-hover-border-gray-200': canUpdate }"
      @input="focusTokenSelector"
      @text-input="debouncedSearchKeyUpdate"
      @focus="handleFocus"
      @blur="handleBlur"
      @mouseover.native="handleMouseOver"
      @mouseout.native="handleMouseOut"
    >
      <template #empty-placeholder>
        <div
          class="add-labels gl-min-w-fit-content gl-display-flex gl-align-items-center gl-text-secondary gl-pr-4 gl-top-2"
          data-testid="empty-state"
        >
          <span v-if="canUpdate" class="gl-ml-2">{{ __('Add labels') }}</span>
          <span v-else class="gl-ml-2">{{ __('None') }}</span>
        </div>
      </template>
      <template #token-content="{ token }">
        <gl-label
          :data-qa-label-name="token.title"
          :title="token.title"
          :description="token.description"
          :background-color="token.color"
          :scoped="scopedLabel(token)"
          :show-close-button="canUpdate"
          @close="removeLabel(token)"
        />
      </template>
      <template #dropdown-item-content="{ dropdownItem }">
        <label-item :label="dropdownItem" />
      </template>
      <template #loading-content>
        <gl-skeleton-loader :height="170">
          <rect width="380" height="20" x="10" y="15" rx="4" />
          <rect width="280" height="20" x="10" y="50" rx="4" />
          <rect width="380" height="20" x="10" y="95" rx="4" />
          <rect width="280" height="20" x="10" y="130" rx="4" />
        </gl-skeleton-loader>
      </template>
    </gl-token-selector>
  </div>
</template>
