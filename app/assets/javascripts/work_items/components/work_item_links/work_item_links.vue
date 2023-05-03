<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { s__ } from '~/locale';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { TYPENAME_ISSUE, TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import getIssueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import { isMetaKey } from '~/lib/utils/common_utils';
import { getParameterByName, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

import { FORM_TYPES, WIDGET_ICONS, WORK_ITEM_STATUS_TEXT } from '../../constants';
import { findHierarchyWidgetChildren, getWorkItemQuery } from '../../utils';
import addHierarchyChildMutation from '../../graphql/add_hierarchy_child.mutation.graphql';
import removeHierarchyChildMutation from '../../graphql/remove_hierarchy_child.mutation.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import WidgetWrapper from '../widget_wrapper.vue';
import WorkItemDetailModal from '../work_item_detail_modal.vue';
import WorkItemLinksForm from './work_item_links_form.vue';
import WorkItemChildrenWrapper from './work_item_children_wrapper.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlLoadingIcon,
    WidgetWrapper,
    WorkItemLinksForm,
    WorkItemDetailModal,
    AbuseCategorySelector,
    WorkItemChildrenWrapper,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath', 'reportAbusePath'],
  props: {
    issuableId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  apollo: {
    workItem: {
      query() {
        return getWorkItemQuery(this.fetchByIid);
      },
      variables() {
        return {
          id: this.issuableGid,
        };
      },
      context: {
        isSingleRequest: true,
      },
      skip() {
        return !this.issuableId;
      },
      error(e) {
        this.error = e.message || this.$options.i18n.fetchError;
      },
      async result() {
        const iid = getParameterByName('work_item_iid');
        this.activeChild = this.children.find((child) => child.iid === iid) ?? {};
        await this.$nextTick();
        if (!isEmpty(this.activeChild)) {
          this.$refs.modal.show();
          return;
        }
        this.updateWorkItemIdUrlQuery();
      },
    },
    parentIssue: {
      query: getIssueDetailsQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_ISSUE, this.issuableId),
        };
      },
      update: (data) => data.issue,
    },
  },
  data() {
    return {
      isShownAddForm: false,
      activeChild: {},
      activeToast: null,
      prefetchedWorkItem: null,
      error: undefined,
      parentIssue: null,
      formType: null,
      workItem: null,
      isReportDrawerOpen: false,
      reportedUserId: 0,
      reportedUrl: '',
    };
  },
  computed: {
    fetchByIid() {
      return false;
    },
    confidential() {
      return this.parentIssue?.confidential || this.workItem?.confidential || false;
    },
    issuableIteration() {
      return this.parentIssue?.iteration;
    },
    issuableMilestone() {
      return this.parentIssue?.milestone;
    },
    children() {
      return this.workItem ? findHierarchyWidgetChildren(this.workItem) : [];
    },
    canUpdate() {
      return this.workItem?.userPermissions.updateWorkItem || false;
    },
    // Only used for children for now but should be extended later to support parents and siblings
    isChildrenEmpty() {
      return this.children?.length === 0;
    },
    issuableGid() {
      return this.issuableId ? convertToGraphQLId(TYPENAME_WORK_ITEM, this.issuableId) : null;
    },
    isLoading() {
      return this.$apollo.queries.workItem.loading;
    },
    childrenIds() {
      return this.children.map((c) => c.id);
    },
    childrenCountLabel() {
      return this.isLoading && this.children.length === 0 ? '...' : this.children.length;
    },
  },
  mounted() {
    this.addWorkItemQuery(getParameterByName('work_item_iid'));
  },
  methods: {
    showAddForm(formType) {
      this.$refs.wrapper.show();
      this.isShownAddForm = true;
      this.formType = formType;
      this.$nextTick(() => {
        this.$refs.wiLinksForm.$refs.wiTitleInput?.$el.focus();
      });
    },
    hideAddForm() {
      this.isShownAddForm = false;
    },
    openChild({ event, child }) {
      if (isMetaKey(event)) {
        return;
      }
      event.preventDefault();
      this.activeChild = child;
      this.$refs.modal.show();
      this.updateWorkItemIdUrlQuery(child);
    },
    async closeModal() {
      this.activeChild = {};
      this.updateWorkItemIdUrlQuery();
    },
    handleWorkItemDeleted(child) {
      this.removeHierarchyChild(child);
      this.activeToast = this.$toast.show(s__('WorkItem|Task deleted'));
    },
    updateWorkItemIdUrlQuery({ iid } = {}) {
      updateHistory({ url: setUrlParams({ work_item_iid: iid }), replace: true });
    },
    async addHierarchyChild(workItem) {
      return this.$apollo.mutate({
        mutation: addHierarchyChildMutation,
        variables: { id: this.issuableGid, workItem },
      });
    },
    async removeHierarchyChild(workItem) {
      return this.$apollo.mutate({
        mutation: removeHierarchyChildMutation,
        variables: { id: this.issuableGid, workItem },
      });
    },
    async updateWorkItem(workItem, childId, parentId) {
      const response = await this.$apollo.mutate({
        mutation: updateWorkItemMutation,
        variables: { input: { id: childId, hierarchyWidget: { parentId } } },
      });

      if (parentId === null) {
        await this.removeHierarchyChild(workItem);
      } else {
        await this.addHierarchyChild(workItem);
      }

      return response;
    },
    async undoChildRemoval(workItem, childId) {
      const { data } = await this.updateWorkItem(workItem, childId, this.issuableGid);

      if (data.workItemUpdate.errors.length === 0) {
        this.activeToast?.hide();
      }
    },
    async removeChild(childId) {
      const { data } = await this.updateWorkItem({ id: childId }, childId, null);

      if (data.workItemUpdate.errors.length === 0) {
        this.activeToast = this.$toast.show(s__('WorkItem|Child removed'), {
          action: {
            text: s__('WorkItem|Undo'),
            onClick: this.undoChildRemoval.bind(this, data.workItemUpdate.workItem, childId),
          },
        });
      }
    },
    addWorkItemQuery(iid) {
      if (!iid) {
        return;
      }

      this.$apollo.addSmartQuery('prefetchedWorkItem', {
        query: workItemByIidQuery,
        variables: {
          fullPath: this.projectPath,
          iid,
        },
        update(data) {
          return data.workspace.workItems.nodes[0];
        },
        context: {
          isSingleRequest: true,
        },
      });
    },
    prefetchWorkItem({ iid }) {
      this.prefetch = setTimeout(
        () => this.addWorkItemQuery(iid),
        DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
      );
    },
    clearPrefetching() {
      clearTimeout(this.prefetch);
    },
    toggleReportAbuseDrawer(isOpen, reply = {}) {
      this.isReportDrawerOpen = isOpen;
      this.reportedUrl = reply.url;
      this.reportedUserId = reply.author ? getIdFromGraphQLId(reply.author.id) : 0;
    },
    openReportAbuseDrawer(reply) {
      this.toggleReportAbuseDrawer(true, reply);
    },
  },
  i18n: {
    title: s__('WorkItem|Tasks'),
    fetchError: s__('WorkItem|Something went wrong when fetching tasks. Please refresh this page.'),
    emptyStateMessage: s__(
      'WorkItem|No tasks are currently assigned. Use tasks to break down this issue into smaller parts.',
    ),
    addChildButtonLabel: s__('WorkItem|Add'),
    addChildOptionLabel: s__('WorkItem|Existing task'),
    createChildOptionLabel: s__('WorkItem|New task'),
  },
  WIDGET_TYPE_TASK_ICON: WIDGET_ICONS.TASK,
  WORK_ITEM_STATUS_TEXT,
  FORM_TYPES,
};
</script>

<template>
  <widget-wrapper
    ref="wrapper"
    :error="error"
    data-testid="work-item-links"
    @dismissAlert="error = undefined"
  >
    <template #header>{{ $options.i18n.title }}</template>
    <template #header-suffix>
      <span
        class="gl-display-inline-flex gl-align-items-center gl-line-height-24 gl-ml-3 gl-font-weight-bold gl-text-gray-500"
        data-testid="children-count"
      >
        <gl-icon :name="$options.WIDGET_TYPE_TASK_ICON" class="gl-mr-2" />
        {{ childrenCountLabel }}
      </span>
    </template>
    <template #header-right>
      <gl-dropdown
        v-if="canUpdate"
        right
        size="small"
        :text="$options.i18n.addChildButtonLabel"
        data-testid="toggle-form"
      >
        <gl-dropdown-item
          data-testid="toggle-create-form"
          @click="showAddForm($options.FORM_TYPES.create)"
        >
          {{ $options.i18n.createChildOptionLabel }}
        </gl-dropdown-item>
        <gl-dropdown-item
          data-testid="toggle-add-form"
          @click="showAddForm($options.FORM_TYPES.add)"
        >
          {{ $options.i18n.addChildOptionLabel }}
        </gl-dropdown-item>
      </gl-dropdown>
    </template>
    <template #body>
      <gl-loading-icon v-if="isLoading" color="dark" class="gl-my-2" />

      <template v-else>
        <div v-if="isChildrenEmpty && !isShownAddForm && !error" data-testid="links-empty">
          <p class="gl-px-3 gl-py-2 gl-mb-0 gl-text-gray-500">
            {{ $options.i18n.emptyStateMessage }}
          </p>
        </div>
        <work-item-links-form
          v-if="isShownAddForm"
          ref="wiLinksForm"
          data-testid="add-links-form"
          :issuable-gid="issuableGid"
          :children-ids="childrenIds"
          :parent-confidential="confidential"
          :parent-iteration="issuableIteration"
          :parent-milestone="issuableMilestone"
          :form-type="formType"
          :parent-work-item-type="workItem.workItemType.name"
          @cancel="hideAddForm"
          @addWorkItemChild="addHierarchyChild"
        />
        <work-item-children-wrapper
          :children="children"
          :project-path="projectPath"
          :can-update="canUpdate"
          :work-item-id="issuableGid"
          @removeChild="removeChild"
          @show-modal="openChild"
        />
        <work-item-detail-modal
          ref="modal"
          :work-item-id="activeChild.id"
          :work-item-iid="activeChild.iid"
          @close="closeModal"
          @workItemDeleted="handleWorkItemDeleted(activeChild)"
          @openReportAbuse="openReportAbuseDrawer"
        />
        <abuse-category-selector
          v-if="isReportDrawerOpen && reportAbusePath"
          :reported-user-id="reportedUserId"
          :reported-from-url="reportedUrl"
          :show-drawer="isReportDrawerOpen"
          @close-drawer="toggleReportAbuseDrawer(false)"
        />
      </template>
    </template>
  </widget-wrapper>
</template>
