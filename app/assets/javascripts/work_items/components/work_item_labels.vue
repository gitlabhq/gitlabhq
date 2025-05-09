<script>
import { GlButton, GlDisclosureDropdown, GlLabel } from '@gitlab/ui';
import { difference, unionBy } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { __, n__, s__ } from '~/locale';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import DropdownContentsCreateView from '~/sidebar/components/labels/labels_select_widget/dropdown_contents_create_view.vue';
import groupLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/group_labels.query.graphql';
import projectLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import { isScopedLabel } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';
import { ISSUABLE_CHANGE_LABEL } from '~/behaviors/shortcuts/keybindings';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateNewWorkItemMutation from '../graphql/update_new_work_item.mutation.graphql';
import { i18n, TRACKING_CATEGORY_SHOW } from '../constants';
import {
  findLabelsWidget,
  formatLabelForListbox,
  newWorkItemId,
  newWorkItemFullPath,
} from '../utils';

export default {
  components: {
    DropdownContentsCreateView,
    GlButton,
    GlDisclosureDropdown,
    GlLabel,
    WorkItemSidebarDropdownWidget,
  },
  mixins: [Tracking.mixin()],
  inject: ['canAdminLabel', 'issuesListPath', 'labelsManagePath'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    isGroup: {
      type: Boolean,
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
      searchLabels: [],
      searchTerm: '',
      searchStarted: false,
      showLabelForm: false,
      updateInProgress: false,
      workItem: {},
      createdLabelId: undefined,
      removeLabelIds: [],
      addLabelIds: [],
      labelsCache: [],
      labelsToShowAtTopOfListbox: [],
      shortcut: ISSUABLE_CHANGE_LABEL,
    };
  },
  computed: {
    isCreateFlow() {
      return this.workItemId === newWorkItemId(this.workItemType);
    },
    workItemFullPath() {
      return this.isCreateFlow
        ? newWorkItemFullPath(this.fullPath, this.workItemType)
        : this.fullPath;
    },
    // eslint-disable-next-line vue/no-unused-properties
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_label',
        property: `type_${this.workItemType}`,
      };
    },
    dropdownText() {
      const selectedLabelsCount =
        this.addLabelIds.length + this.widgetLabelsIds.length - this.removeLabelIds.length;
      return this.addLabelIds.length > 0 || this.widgetLabelsIds.length > 0
        ? n__('%d label', '%d labels', selectedLabelsCount)
        : __('No labels');
    },
    isLoadingLabels() {
      return this.$apollo.queries.searchLabels.loading;
    },
    fuzzyFilteredLabels() {
      return this.searchTerm
        ? fuzzaldrinPlus.filter(this.searchLabels, this.searchTerm, { key: ['title'] })
        : this.searchLabels;
    },
    listboxItems() {
      const listboxLabels = this.fuzzyFilteredLabels.map(formatLabelForListbox);

      if (this.searchTerm || this.widgetLabelsIds.length === 0) {
        return listboxLabels;
      }

      const selectedLabels = this.labelsToShowAtTopOfListbox.map(formatLabelForListbox);

      return [
        { text: __('Selected'), options: selectedLabels },
        { text: __('All'), textSrOnly: true, options: listboxLabels },
      ];
    },
    labelsWidget() {
      return findLabelsWidget(this.workItem);
    },
    widgetLabels() {
      return this.labelsWidget?.labels?.nodes || [];
    },
    widgetLabelsIds() {
      return this.widgetLabels.map(({ id }) => id);
    },
    allowsScopedLabels() {
      return this.labelsWidget?.allowsScopedLabels;
    },
    createLabelText() {
      return this.isGroup ? __('Create group label') : __('Create project label');
    },
    manageLabelText() {
      return this.isGroup ? __('Manage group labels') : __('Manage project labels');
    },
    workspaceType() {
      return this.isGroup ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
  },
  watch: {
    searchTerm(newVal, oldVal) {
      if (newVal === '' && oldVal !== '') {
        const selectedIds = [...this.widgetLabelsIds, ...this.addLabelIds].filter(
          (x) => !this.removeLabelIds.includes(x),
        );

        this.labelsToShowAtTopOfListbox = this.labelsCache.filter(({ id }) =>
          selectedIds.includes(id),
        );
      }
    },
    widgetLabels(newVal) {
      this.labelsToShowAtTopOfListbox = newVal;
    },
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace?.workItem || {};
      },
      result({ data }) {
        const labels = findLabelsWidget(data?.workspace?.workItem)?.labels?.nodes || [];
        this.labelsCache = unionBy(this.labelsCache, labels, 'id');
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
        return data.workspace?.labels?.nodes ?? [];
      },
      result({ data }) {
        const labels = data?.workspace?.labels?.nodes || [];
        this.labelsCache = unionBy(this.labelsCache, labels, 'id');
      },
      error() {
        this.$emit(
          'error',
          s__('WorkItem|Something went wrong when fetching labels. Please try again.'),
        );
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
    },
    removeLabel({ id }) {
      this.removeLabelIds.push(id);
      this.updateLabels();
    },
    updateLabel(labels) {
      this.removeLabelIds = difference(this.widgetLabelsIds, labels);
      this.addLabelIds = difference(labels, this.widgetLabelsIds);
    },
    async updateLabels(labels) {
      if (labels?.length === 0) {
        this.removeLabelIds = this.widgetLabelsIds;
        this.addLabelIds = [];
      }

      if (!this.addLabelIds.length && !this.removeLabelIds.length) {
        return;
      }

      this.updateInProgress = true;

      if (this.isCreateFlow) {
        const selectedIds = [...this.widgetLabelsIds, ...this.addLabelIds].filter(
          (x) => !this.removeLabelIds.includes(x),
        );

        await this.$apollo.mutate({
          mutation: updateNewWorkItemMutation,
          variables: {
            input: {
              workItemType: this.workItemType,
              fullPath: this.fullPath,
              labels: this.labelsCache.filter(({ id }) => selectedIds.includes(id)),
            },
          },
        });

        this.updateInProgress = false;
        this.addLabelIds = [];
        this.removeLabelIds = [];
        return;
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
          throw new Error();
        }

        this.track('updated_labels');
        this.$emit('labelsUpdated', [...this.addLabelIds, ...this.removeLabelIds]);
      } catch {
        this.$emit('error', i18n.updateError);
      } finally {
        this.searchTerm = '';
        this.addLabelIds = [];
        this.removeLabelIds = [];
        this.updateInProgress = false;
      }
    },
    scopedLabel(label) {
      return this.allowsScopedLabels && isScopedLabel(label);
    },
    labelFilterUrl(label) {
      return `${this.issuesListPath}?label_name[]=${encodeURIComponent(label.title)}`;
    },
    handleLabelCreated(label) {
      this.showLabelForm = false;
      this.createdLabelId = label.id;
      this.addLabelIds.push(label.id);
    },
  },
};
</script>

<template>
  <work-item-sidebar-dropdown-widget
    :dropdown-label="__('Labels')"
    :can-update="canUpdate"
    :created-label-id="createdLabelId"
    dropdown-name="label"
    :loading="isLoadingLabels"
    :list-items="listboxItems"
    :item-value="widgetLabelsIds"
    :update-in-progress="updateInProgress"
    :toggle-dropdown-text="dropdownText"
    :header-text="__('Select labels')"
    :reset-button-label="__('Clear')"
    :shortcut="shortcut"
    show-footer
    multi-select
    clear-search-on-item-select
    data-testid="work-item-labels"
    @dropdownShown="onDropdownShown"
    @searchStarted="search"
    @updateValue="updateLabels"
    @updateSelected="updateLabel"
  >
    <template #list-item="{ item }">
      <div class="gl-flex gl-items-center gl-gap-3 gl-break-anywhere">
        <span
          :style="{ background: item.color }"
          class="gl-border gl-h-3 gl-w-5 gl-shrink-0 gl-rounded-base gl-border-white"
        ></span>
        {{ item.text }}
      </div>
    </template>
    <template #readonly>
      <div class="gl-mt-1 gl-flex gl-flex-wrap gl-gap-2" data-testid="selected-label-content">
        <gl-label
          v-for="label in widgetLabels"
          :key="label.id"
          :title="label.title"
          :description="label.description"
          :background-color="label.color"
          :scoped="scopedLabel(label)"
          :show-close-button="canUpdate"
          :target="labelFilterUrl(label)"
          :data-testid="label.title"
          @close="removeLabel(label)"
        />
      </div>
    </template>
    <template #footer>
      <gl-button
        v-if="canAdminLabel"
        class="!gl-justify-start"
        block
        category="tertiary"
        data-testid="create-label"
        @click="showLabelForm = true"
      >
        {{ createLabelText }}
      </gl-button>
      <gl-button
        class="!gl-mt-2 !gl-justify-start"
        block
        category="tertiary"
        :href="labelsManagePath"
        data-testid="manage-labels"
      >
        {{ manageLabelText }}
      </gl-button>
    </template>
    <template v-if="showLabelForm" #body>
      <gl-disclosure-dropdown
        class="work-item-sidebar-dropdown"
        block
        start-opened
        :toggle-text="dropdownText"
      >
        <div
          class="gl-border-b gl-mb-4 gl-pb-3 gl-pl-4 gl-pt-2 gl-text-sm gl-font-bold gl-leading-24"
        >
          {{ __('Create label') }}
        </div>
        <dropdown-contents-create-view
          class="gl-mb-2"
          :attr-workspace-path="fullPath"
          :full-path="fullPath"
          :label-create-type="workspaceType"
          :search-key="searchTerm"
          :workspace-type="workspaceType"
          @hideCreateView="showLabelForm = false"
          @labelCreated="handleLabelCreated"
        />
      </gl-disclosure-dropdown>
    </template>
  </work-item-sidebar-dropdown-widget>
</template>
