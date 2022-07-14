<script>
import { GlTokenSelector, GlLabel, GlSkeletonLoader } from '@gitlab/ui';
import { debounce } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Tracking from '~/tracking';
import labelSearchQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/project_labels.query.graphql';
import LabelItem from '~/vue_shared/components/sidebar/labels_select_widget/label_item.vue';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { isScopedLabel, scopedLabelKey } from '~/lib/utils/common_utils';
import workItemQuery from '../graphql/work_item.query.graphql';
import localUpdateWorkItemMutation from '../graphql/local_update_work_item.mutation.graphql';

import { i18n, TRACKING_CATEGORY_SHOW, WIDGET_TYPE_LABELS } from '../constants';

function isTokenSelectorElement(el) {
  return el?.classList.contains('gl-label-close') || el?.classList.contains('dropdown-item');
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
    };
  },
  apollo: {
    workItem: {
      query: workItemQuery,
      variables() {
        return {
          id: this.workItemId,
        };
      },
      skip() {
        return !this.workItemId;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
    searchLabels: {
      query: labelSearchQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.searchKey,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace?.labels?.nodes.map((node) => addClass({ ...node, ...node.label }));
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_labels',
        property: `type_${this.workItem.workItemType?.name}`,
      };
    },
    allowScopedLabels() {
      return this.labelsWidget.allowScopedLabels;
    },
    listEmpty() {
      return this.labels.length === 0;
    },
    containerClass() {
      return !this.isEditing ? 'gl-shadow-none!' : '';
    },
    isLoading() {
      return this.$apollo.queries.searchLabels.loading;
    },
    labelsWidget() {
      return this.workItem?.mockWidgets?.find((widget) => widget.type === WIDGET_TYPE_LABELS);
    },
    labels() {
      return this.labelsWidget?.nodes || [];
    },
  },
  watch: {
    labels(newVal) {
      if (!this.isEditing) {
        this.localLabels = newVal.map(addClass);
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
    },
    setLabels(event) {
      this.searchKey = '';
      if (isTokenSelectorElement(event.relatedTarget) || !this.isEditing) return;
      this.isEditing = false;
      this.$apollo
        .mutate({
          mutation: localUpdateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              labels: this.localLabels,
            },
          },
        })
        .catch((e) => {
          this.$emit('error', e);
        });
      this.track('updated_labels');
    },
    handleFocus() {
      this.isEditing = true;
      this.searchStarted = true;
    },
    async focusTokenSelector(labels) {
      if (this.allowScopedLabels) {
        const newLabel = labels[labels.length - 1];
        const existingLabels = labels.slice(0, labels.length - 1);

        const newLabelKey = scopedLabelKey(newLabel);

        const removeLabelsWithSameScope = existingLabels.filter((label) => {
          const sameKey = newLabelKey === scopedLabelKey(label);
          return !sameKey;
        });

        this.localLabels = [...removeLabelsWithSameScope, newLabel];
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
  <div class="form-row gl-mb-5 work-item-labels gl-relative">
    <span
      class="gl-font-weight-bold gl-mt-2 col-lg-2 col-3 gl-pt-2 min-w-fit-content gl-overflow-wrap-break"
      data-testid="labels-title"
      >{{ __('Labels') }}</span
    >
    <gl-token-selector
      ref="tokenSelector"
      v-model="localLabels"
      :container-class="containerClass"
      :dropdown-items="searchLabels"
      :loading="isLoading"
      :view-only="!canUpdate"
      class="gl-flex-grow-1 gl-border gl-border-white gl-hover-border-gray-200 gl-rounded-base col-9 gl-align-self-start gl-px-0! gl-mx-2!"
      @input="focusTokenSelector"
      @text-input="debouncedSearchKeyUpdate"
      @focus="handleFocus"
      @blur="setLabels"
      @mouseover.native="handleMouseOver"
      @mouseout.native="handleMouseOut"
    >
      <template #empty-placeholder>
        <div
          class="add-labels gl-min-w-fit-content gl-display-flex gl-align-items-center gl-text-gray-400 gl-pr-4 gl-top-2"
          data-testid="empty-state"
        >
          <span v-if="canUpdate" class="gl-ml-2">{{ __('Select labels') }}</span>
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
