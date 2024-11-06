<script>
import {
  GlAlert,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_ISSUE, TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import getIssueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import { getParameterByName, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import {
  FORM_TYPES,
  WIDGET_ICONS,
  WORK_ITEM_STATUS_TEXT,
  TASKS_ANCHOR,
  DEFAULT_PAGE_SIZE_CHILD_ITEMS,
  DETAIL_VIEW_QUERY_PARAM_NAME,
  WORKITEM_LINKS_SHOWLABELS_LOCALSTORAGEKEY,
  WORKITEM_TREE_SHOWCLOSED_LOCALSTORAGEKEY,
} from '../../constants';
import {
  findHierarchyWidgets,
  saveToggleToLocalStorage,
  getToggleFromLocalStorage,
  getItems,
} from '../../utils';
import { removeHierarchyChild } from '../../graphql/cache_utils';
import getWorkItemTreeQuery from '../../graphql/work_item_tree.query.graphql';
import WorkItemChildrenLoadMore from '../shared/work_item_children_load_more.vue';
import WorkItemMoreActions from '../shared/work_item_more_actions.vue';
import WorkItemDetailModal from '../work_item_detail_modal.vue';
import WorkItemAbuseModal from '../work_item_abuse_modal.vue';
import WorkItemLinksForm from './work_item_links_form.vue';
import WorkItemChildrenWrapper from './work_item_children_wrapper.vue';

export default {
  components: {
    GlAlert,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    CrudComponent,
    WorkItemLinksForm,
    WorkItemDetailModal,
    WorkItemAbuseModal,
    WorkItemChildrenWrapper,
    WorkItemChildrenLoadMore,
    WorkItemMoreActions,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['fullPath', 'reportAbusePath'],
  props: {
    issuableId: {
      type: Number,
      required: true,
    },
    issuableIid: {
      type: Number,
      required: true,
    },
  },
  apollo: {
    workItem: {
      query: getWorkItemTreeQuery,
      variables() {
        return {
          id: this.issuableGid,
          pageSize: DEFAULT_PAGE_SIZE_CHILD_ITEMS,
          endCursor: '',
        };
      },
      update(data) {
        return data.workItem ?? {};
      },
      skip() {
        return !this.issuableId;
      },
      error(e) {
        this.error = e.message || this.$options.i18n.fetchError;
      },
      async result() {
        const iid = getParameterByName('work_item_iid');
        const id = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);
        this.activeChild =
          this.children.find(
            (child) => getIdFromGraphQLId(child.id) === getIdFromGraphQLId(id) || child.iid === iid,
          ) ?? {};
        await this.$nextTick();
        if (!isEmpty(this.activeChild)) {
          this.$refs.modal.show();
          return;
        }
        this.updateQueryParam();
        if (this.hasNextPage && this.children.length === 0) {
          this.fetchNextPage();
        }
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
      activeChild: {},
      error: undefined,
      parentIssue: null,
      formType: null,
      workItem: null,
      isReportModalOpen: false,
      reportedUserId: 0,
      reportedUrl: '',
      widgetName: TASKS_ANCHOR,
      showLabels: true,
      showClosed: true,
      fetchNextPageInProgress: false,
      disableContent: false,
      showLabelsLocalStorageKey: WORKITEM_LINKS_SHOWLABELS_LOCALSTORAGEKEY,
      showClosedLocalStorageKey: WORKITEM_TREE_SHOWCLOSED_LOCALSTORAGEKEY,
    };
  },
  computed: {
    confidential() {
      return this.parentIssue?.confidential || this.workItem?.confidential || false;
    },
    iid() {
      return String(this.issuableIid);
    },
    issuableIteration() {
      return this.parentIssue?.iteration;
    },
    issuableMilestone() {
      return this.parentIssue?.milestone;
    },
    hierarchyWidget() {
      return this.workItem ? findHierarchyWidgets(this.workItem.widgets) : {};
    },
    children() {
      return this.hierarchyWidget?.children?.nodes || [];
    },
    canUpdate() {
      return this.workItem?.userPermissions.updateWorkItem || false;
    },
    canAddTask() {
      return this.workItem?.userPermissions.adminParentLink || false;
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
    activeChildNamespaceFullPath() {
      return this.activeChild.namespace?.fullPath;
    },
    pageInfo() {
      return this.hierarchyWidget?.children?.pageInfo;
    },
    endCursor() {
      return this.pageInfo?.endCursor || '';
    },
    hasNextPage() {
      return this.pageInfo?.hasNextPage;
    },
    workItemType() {
      return this.workItem?.workItemType?.name || '';
    },
    hasAllChildItemsHidden() {
      const filterClosed = getItems(this.showClosed);
      return filterClosed(this.children).length === 0;
    },
  },
  mounted() {
    this.showLabels = getToggleFromLocalStorage(this.showLabelsLocalStorageKey);
    this.showClosed = getToggleFromLocalStorage(this.showClosedLocalStorageKey);
  },
  methods: {
    showAddForm(formType) {
      this.$refs.workItemsLinks.showForm();
      this.formType = formType;
      this.$nextTick(() => {
        this.$refs.wiLinksForm.$refs.wiTitleInput?.$el.focus();
      });
    },
    hideAddForm() {
      this.$refs.workItemsLinks.hideForm();
    },
    openChild({ event, child }) {
      event.preventDefault();
      this.activeChild = child;
      this.$refs.modal.show();
      this.updateQueryParam(child.id);
    },
    async closeModal() {
      this.updateQueryParam();
    },
    handleWorkItemDeleted(child) {
      const { defaultClient: cache } = this.$apollo.provider.clients;
      removeHierarchyChild({
        cache,
        fullPath: this.fullPath,
        iid: this.iid,
        workItem: child,
      });
      this.$toast.show(s__('WorkItem|Task deleted'));
    },
    updateQueryParam(id) {
      updateHistory({
        url: setUrlParams({ [DETAIL_VIEW_QUERY_PARAM_NAME]: getIdFromGraphQLId(id) }),
        replace: true,
      });
    },
    toggleReportAbuseModal(isOpen, reply = {}) {
      this.isReportModalOpen = isOpen;
      this.reportedUrl = reply.url;
      this.reportedUserId = reply.author ? getIdFromGraphQLId(reply.author.id) : 0;
    },
    openReportAbuseModal(reply) {
      this.toggleReportAbuseModal(true, reply);
    },
    toggleShowLabels() {
      this.showLabels = !this.showLabels;
      saveToggleToLocalStorage(this.showLabelsLocalStorageKey, this.showLabels);
    },
    toggleShowClosed() {
      this.showClosed = !this.showClosed;
      saveToggleToLocalStorage(this.showClosedLocalStorageKey, this.showClosed);
    },
    setShowLabelsFromLocalStorage() {},
    async fetchNextPage() {
      if (this.hasNextPage && !this.fetchNextPageInProgress) {
        this.fetchNextPageInProgress = true;
        try {
          await this.$apollo.queries.workItem.fetchMore({
            variables: {
              endCursor: this.endCursor,
            },
          });
        } catch (error) {
          createAlert({
            message: s__('Hierarchy|Something went wrong while fetching children.'),
            captureError: true,
            error,
          });
        } finally {
          this.fetchNextPageInProgress = false;
        }
      }
    },
  },
  i18n: {
    title: s__('WorkItem|Child items'),
    fetchError: s__(
      'WorkItem|Something went wrong when fetching child items. Please refresh this page.',
    ),
    emptyStateMessage: s__(
      'WorkItem|No child items are currently assigned. Use child items to break down this issue into smaller parts.',
    ),
    addChildButtonLabel: s__('WorkItem|Add'),
    addChildOptionLabel: s__('WorkItem|Existing task'),
    createChildOptionLabel: s__('WorkItem|New task'),
    noChildItemsOpen: s__('WorkItem|No child items are currently open.'),
  },
  WIDGET_TYPE_TASK_ICON: WIDGET_ICONS.TASK,
  WORK_ITEM_STATUS_TEXT,
  FORM_TYPES,
};
</script>

<template>
  <crud-component
    ref="workItemsLinks"
    :anchor-id="widgetName"
    :title="$options.i18n.title"
    :icon="$options.WIDGET_TYPE_TASK_ICON"
    :count="childrenCountLabel"
    :is-loading="isLoading && !fetchNextPageInProgress"
    is-collapsible
    data-testid="work-item-links"
  >
    <template #actions>
      <gl-disclosure-dropdown
        v-if="canUpdate && canAddTask"
        placement="bottom-end"
        size="small"
        :toggle-text="$options.i18n.addChildButtonLabel"
        data-testid="toggle-form"
      >
        <gl-disclosure-dropdown-item
          data-testid="toggle-create-form"
          @action="showAddForm($options.FORM_TYPES.create)"
        >
          <template #list-item>
            {{ $options.i18n.createChildOptionLabel }}
          </template>
        </gl-disclosure-dropdown-item>
        <gl-disclosure-dropdown-item
          data-testid="toggle-add-form"
          @action="showAddForm($options.FORM_TYPES.add)"
        >
          <template #list-item>
            {{ $options.i18n.addChildOptionLabel }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown>
      <work-item-more-actions
        :work-item-iid="iid"
        :full-path="fullPath"
        :work-item-type="workItemType"
        :show-labels="showLabels"
        :show-closed="showClosed"
        :show-view-roadmap-action="false"
        @toggle-show-labels="toggleShowLabels"
        @toggle-show-closed="toggleShowClosed"
      />
    </template>

    <template v-if="isChildrenEmpty && !error" #empty>
      {{ $options.i18n.emptyStateMessage }}
    </template>

    <template #form>
      <work-item-links-form
        ref="wiLinksForm"
        data-testid="add-links-form"
        :full-path="fullPath"
        :full-name="workItem.namespace.fullName"
        :is-group="false"
        :issuable-gid="issuableGid"
        :work-item-iid="iid"
        :children-ids="childrenIds"
        :parent-confidential="confidential"
        :parent-iteration="issuableIteration"
        :parent-milestone="issuableMilestone"
        :form-type="formType"
        :parent-work-item-type="workItemType"
        @update-in-progress="disableContent = $event"
        @cancel="hideAddForm"
      />
    </template>

    <template #default>
      <gl-alert v-if="error" variant="danger" @dismiss="error = undefined">
        {{ error }}
      </gl-alert>
      <div v-if="!hasAllChildItemsHidden" class="!gl-px-3 gl-pb-3 gl-pt-2">
        <work-item-children-wrapper
          v-if="workItem"
          :children="children"
          :parent="workItem"
          :can-update="canUpdate"
          :full-path="fullPath"
          :work-item-id="issuableGid"
          :work-item-iid="iid"
          :show-labels="showLabels"
          :show-closed="showClosed"
          :disable-content="disableContent"
          :has-indirect-children="false"
          @error="error = $event"
          @show-modal="openChild"
        />
        <work-item-children-load-more
          v-if="hasNextPage"
          data-testid="work-item-load-more"
          :fetch-next-page-in-progress="fetchNextPageInProgress"
          @fetch-next-page="fetchNextPage"
        />
      </div>
      <work-item-detail-modal
        ref="modal"
        :work-item-id="activeChild.id"
        :work-item-iid="activeChild.iid"
        :work-item-full-path="activeChildNamespaceFullPath"
        @close="closeModal"
        @workItemDeleted="handleWorkItemDeleted(activeChild)"
        @openReportAbuse="openReportAbuseModal"
      />
      <work-item-abuse-modal
        v-if="isReportModalOpen && reportAbusePath"
        :show-modal="isReportModalOpen"
        :reported-user-id="reportedUserId"
        :reported-from-url="reportedUrl"
        @close-modal="toggleReportAbuseModal(false)"
      />

      <div
        v-if="hasAllChildItemsHidden"
        class="gl-text-subtle"
        data-testid="work-item-no-child-items-open"
      >
        {{ $options.i18n.noChildItemsOpen }}
      </div>
    </template>
  </crud-component>
</template>
