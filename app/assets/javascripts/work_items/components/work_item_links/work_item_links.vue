<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { s__ } from '~/locale';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { TYPENAME_ISSUE, TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getIssueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import { isMetaKey } from '~/lib/utils/common_utils';
import { getParameterByName, setUrlParams, updateHistory } from '~/lib/utils/url_utility';

import {
  FORM_TYPES,
  WIDGET_ICONS,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_STATUS_TEXT,
} from '../../constants';
import getWorkItemLinksQuery from '../../graphql/work_item_links.query.graphql';
import addHierarchyChildMutation from '../../graphql/add_hierarchy_child.mutation.graphql';
import removeHierarchyChildMutation from '../../graphql/remove_hierarchy_child.mutation.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import workItemQuery from '../../graphql/work_item.query.graphql';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import WidgetWrapper from '../widget_wrapper.vue';
import WorkItemDetailModal from '../work_item_detail_modal.vue';
import WorkItemLinkChild from './work_item_link_child.vue';
import WorkItemLinksForm from './work_item_links_form.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlLoadingIcon,
    WidgetWrapper,
    WorkItemLinkChild,
    WorkItemLinksForm,
    WorkItemDetailModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['projectPath'],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    issuableId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  apollo: {
    workItem: {
      query: getWorkItemLinksQuery,
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
        const { id, iid } = this.childUrlParams();
        this.activeChild = this.fetchByIid
          ? this.children.find((child) => child.iid === iid) ?? {}
          : this.children.find((child) => child.id === id) ?? {};
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
    };
  },
  computed: {
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
      return (
        this.workItem?.widgets.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)?.children
          .nodes ?? []
      );
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
    fetchByIid() {
      return true;
    },
  },
  mounted() {
    if (!isEmpty(this.childUrlParams())) {
      this.addWorkItemQuery(this.childUrlParams());
    }
  },
  methods: {
    childUrlParams() {
      const params = {};
      if (this.fetchByIid) {
        const iid = getParameterByName('work_item_iid');
        if (iid) {
          params.iid = iid;
        }
      } else {
        const workItemId = getParameterByName('work_item_id');
        if (workItemId) {
          params.id = convertToGraphQLId(TYPENAME_WORK_ITEM, workItemId);
        }
      }
      return params;
    },
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
    openChild(child, e) {
      if (isMetaKey(e)) {
        return;
      }
      e.preventDefault();
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
    updateWorkItemIdUrlQuery({ id, iid } = {}) {
      const params = this.fetchByIid
        ? { work_item_iid: iid }
        : { work_item_id: getIdFromGraphQLId(id) };
      updateHistory({ url: setUrlParams(params), replace: true });
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
    addWorkItemQuery({ id, iid }) {
      const variables = this.fetchByIid
        ? {
            fullPath: this.projectPath,
            iid,
          }
        : {
            id,
          };
      this.$apollo.addSmartQuery('prefetchedWorkItem', {
        query() {
          return this.fetchByIid ? workItemByIidQuery : workItemQuery;
        },
        variables,
        update(data) {
          return this.fetchByIid ? data.workspace.workItems.nodes[0] : data.workItem;
        },
        context: {
          isSingleRequest: true,
        },
      });
    },
    prefetchWorkItem({ id, iid }) {
      this.prefetch = setTimeout(
        () => this.addWorkItemQuery({ id, iid }),
        DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
      );
    },
    clearPrefetching() {
      clearTimeout(this.prefetch);
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
        <work-item-link-child
          v-for="child in children"
          :key="child.id"
          :project-path="projectPath"
          :can-update="canUpdate"
          :issuable-gid="issuableGid"
          :child-item="child"
          @click="openChild(child, $event)"
          @mouseover="prefetchWorkItem(child)"
          @mouseout="clearPrefetching"
          @removeChild="removeChild"
        />
        <work-item-detail-modal
          ref="modal"
          :work-item-id="activeChild.id"
          :work-item-iid="activeChild.iid"
          @close="closeModal"
          @workItemDeleted="handleWorkItemDeleted(activeChild)"
        />
      </template>
    </template>
  </widget-wrapper>
</template>
