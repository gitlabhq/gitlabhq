<script>
import { GlLabel } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { difference } from 'lodash';
import { __, n__ } from '~/locale';
import WorkItemSidebarDropdownWidgetWithEdit from '~/work_items/components/shared/work_item_sidebar_dropdown_widget_with_edit.vue';
import groupLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/group_labels.query.graphql';
import projectLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import { isScopedLabel } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';
import groupWorkItemByIidQuery from '../graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import { i18n, I18N_WORK_ITEM_ERROR_FETCHING_LABELS, TRACKING_CATEGORY_SHOW } from '../constants';
import { isLabelsWidget } from '../utils';

export default {
  components: {
    WorkItemSidebarDropdownWidgetWithEdit,
    GlLabel,
  },
  mixins: [Tracking.mixin()],
  inject: {
    issuesListPath: {
      type: String,
    },
    isGroup: {
      type: Boolean,
    },
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchTerm: '',
      searchStarted: false,
      updateInProgress: false,
      removeLabelIds: [],
      addLabelIds: [],
    };
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_label',
        property: `type_${this.workItemType}`,
      };
    },
    areLabelsSelected() {
      return this.addLabelIds.length > 0 || this.itemValues.length > 0;
    },
    selectedLabelCount() {
      return this.addLabelIds.length + this.itemValues.length - this.removeLabelIds.length;
    },
    dropDownLabelText() {
      return n__('%d label', '%d labels', this.selectedLabelCount);
    },
    dropdownText() {
      return this.areLabelsSelected ? `${this.dropDownLabelText}` : __('No labels');
    },
    isLoadingLabels() {
      return this.$apollo.queries.searchLabels.loading;
    },
    visibleLabels() {
      if (this.searchTerm) {
        return fuzzaldrinPlus.filter(this.searchLabels, this.searchTerm, {
          key: ['title'],
        });
      }
      return this.searchLabels;
    },
    labelsList() {
      return this.visibleLabels?.map(({ id, title, color }) => ({
        value: id,
        text: title,
        color,
      }));
    },
    labelsWidget() {
      return this.workItem?.widgets?.find(isLabelsWidget);
    },
    localLabels() {
      return this.labelsWidget?.labels?.nodes || [];
    },
    itemValues() {
      return this.localLabels.map(({ id }) => id);
    },
    allowsScopedLabels() {
      return this.labelsWidget?.allowsScopedLabels;
    },
  },
  apollo: {
    workItem: {
      query() {
        return this.isGroup ? groupWorkItemByIidQuery : workItemByIidQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace?.workItems?.nodes[0] || {};
      },
      skip() {
        return !this.workItemIid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
    searchLabels: {
      query() {
        return this.isGroup ? groupLabelsQuery : projectLabelsQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.searchTerm,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace?.labels?.nodes;
      },
      error() {
        this.$emit('error', I18N_WORK_ITEM_ERROR_FETCHING_LABELS);
      },
    },
  },
  methods: {
    onDropdownShown() {
      this.searchTerm = '';
      this.searchStarted = true;
    },
    search(searchTerm) {
      this.searchTerm = searchTerm;
      this.searchStarted = true;
    },
    removeLabel({ id }) {
      this.removeLabelIds.push(id);
      this.updateLabels();
    },
    updateLabel(labels) {
      this.removeLabelIds = difference(this.itemValues, labels);
      this.addLabelIds = difference(labels, this.itemValues);
    },
    async updateLabels(labels) {
      this.searchTerm = '';
      this.updateInProgress = true;

      if (labels && labels.length === 0) {
        this.removeLabelIds = this.itemValues;
        this.addLabelIds = [];
      }

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
      } finally {
        this.updateInProgress = false;
      }
    },
    scopedLabel(label) {
      return this.allowsScopedLabels && isScopedLabel(label);
    },
    isSelected(id) {
      return this.itemValues.includes(id) || this.addLabelIds.includes(id);
    },
    throwUpdateError() {
      this.$emit('error', i18n.updateError);
      this.addLabelIds = [];
      this.removeLabelIds = [];
    },
    labelFilterUrl(label) {
      return `${this.issuesListPath}?label_name[]=${encodeURIComponent(label.title)}`;
    },
  },
};
</script>

<template>
  <work-item-sidebar-dropdown-widget-with-edit
    :dropdown-label="__('Labels')"
    :can-update="canUpdate"
    dropdown-name="label"
    :loading="isLoadingLabels"
    :list-items="labelsList"
    :item-value="itemValues"
    :update-in-progress="updateInProgress"
    :toggle-dropdown-text="dropdownText"
    :header-text="__('Select labels')"
    :reset-button-label="__('Clear')"
    :multi-select="true"
    clear-search-on-item-select
    data-testid="work-item-labels-with-edit"
    @dropdownShown="onDropdownShown"
    @searchStarted="search"
    @updateValue="updateLabels"
    @updateSelected="updateLabel"
  >
    <template #list-item="{ item }">
      <span>
        <span
          :style="{ background: item.color }"
          :class="{ 'gl-border gl-border-white': isSelected(item.value) }"
          class="gl-display-inline-block gl-rounded-base gl-mr-1 gl-w-5 gl-h-3 gl-vertical-align-middle gl-mt-n1"
        ></span>
        {{ item.text }}
      </span>
    </template>
    <template #readonly>
      <div class="gl-display-flex gl-gap-2 gl-flex-wrap gl-mt-1">
        <gl-label
          v-for="label in localLabels"
          :key="label.id"
          :title="label.title"
          :description="label.description"
          :background-color="label.color"
          :scoped="scopedLabel(label)"
          :show-close-button="canUpdate"
          :target="labelFilterUrl(label)"
          @close="removeLabel(label)"
        />
      </div>
    </template>
  </work-item-sidebar-dropdown-widget-with-edit>
</template>
