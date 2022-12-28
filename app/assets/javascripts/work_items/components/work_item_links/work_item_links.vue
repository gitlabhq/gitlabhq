<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
  GlAlert,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { produce } from 'immer';
import { isEmpty } from 'lodash';
import { s__ } from '~/locale';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getIssueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import { isMetaKey, parseBoolean } from '~/lib/utils/common_utils';
import { setUrlParams, updateHistory, getParameterByName } from '~/lib/utils/url_utility';

import {
  FORM_TYPES,
  WIDGET_ICONS,
  WORK_ITEM_STATUS_TEXT,
  WIDGET_TYPE_HIERARCHY,
} from '../../constants';
import getWorkItemLinksQuery from '../../graphql/work_item_links.query.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import workItemQuery from '../../graphql/work_item.query.graphql';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import WorkItemDetailModal from '../work_item_detail_modal.vue';
import WorkItemLinkChild from './work_item_link_child.vue';
import WorkItemLinksForm from './work_item_links_form.vue';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlAlert,
    GlLoadingIcon,
    WorkItemLinkChild,
    WorkItemLinksForm,
    WorkItemDetailModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['projectPath', 'iid'],
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
      skip() {
        return !this.issuableId;
      },
      error(e) {
        this.error = e.message || this.$options.i18n.fetchError;
      },
      async result() {
        const { id, iid } = this.childUrlParams;
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
          fullPath: this.projectPath,
          iid: String(this.iid),
        };
      },
      update(data) {
        return data.workspace?.issuable;
      },
    },
  },
  data() {
    return {
      isShownAddForm: false,
      isOpen: true,
      activeChild: {},
      activeToast: null,
      prefetchedWorkItem: null,
      error: undefined,
      parentIssue: null,
      formType: null,
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
    toggleIcon() {
      return this.isOpen ? 'chevron-lg-up' : 'chevron-lg-down';
    },
    toggleLabel() {
      return this.isOpen ? s__('WorkItem|Collapse tasks') : s__('WorkItem|Expand tasks');
    },
    issuableGid() {
      return this.issuableId ? convertToGraphQLId(TYPE_WORK_ITEM, this.issuableId) : null;
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
      return this.glFeatures.useIidInWorkItemsPath && parseBoolean(getParameterByName('iid_path'));
    },
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
          params.id = convertToGraphQLId(TYPE_WORK_ITEM, workItemId);
        }
      }
      return params;
    },
  },
  mounted() {
    if (!isEmpty(this.childUrlParams)) {
      this.addWorkItemQuery(this.childUrlParams);
    }
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    },
    showAddForm(formType) {
      this.isOpen = true;
      this.isShownAddForm = true;
      this.formType = formType;
      this.$nextTick(() => {
        this.$refs.wiLinksForm.$refs.wiTitleInput?.$el.focus();
      });
    },
    hideAddForm() {
      this.isShownAddForm = false;
    },
    addChild(child) {
      const { defaultClient: client } = this.$apollo.provider.clients;
      this.toggleChildFromCache(child, child.id, client);
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
    handleWorkItemDeleted(childId) {
      const { defaultClient: client } = this.$apollo.provider.clients;
      this.toggleChildFromCache(null, childId, client);
      this.activeToast = this.$toast.show(s__('WorkItem|Task deleted'));
    },
    updateWorkItemIdUrlQuery({ id, iid } = {}) {
      const params = this.fetchByIid
        ? { work_item_iid: iid }
        : { work_item_id: getIdFromGraphQLId(id) };
      updateHistory({ url: setUrlParams(params), replace: true });
    },
    toggleChildFromCache(workItem, childId, store) {
      const sourceData = store.readQuery({
        query: getWorkItemLinksQuery,
        variables: { id: this.issuableGid },
      });

      const newData = produce(sourceData, (draftState) => {
        const widgetHierarchy = draftState.workItem.widgets.find(
          (widget) => widget.type === WIDGET_TYPE_HIERARCHY,
        );

        const index = widgetHierarchy.children.nodes.findIndex((child) => child.id === childId);

        if (index >= 0) {
          widgetHierarchy.children.nodes.splice(index, 1);
        } else {
          widgetHierarchy.children.nodes.push(workItem);
        }
      });

      store.writeQuery({
        query: getWorkItemLinksQuery,
        variables: { id: this.issuableGid },
        data: newData,
      });
    },
    async updateWorkItem(workItem, childId, parentId) {
      return this.$apollo.mutate({
        mutation: updateWorkItemMutation,
        variables: { input: { id: childId, hierarchyWidget: { parentId } } },
        update: (store) => this.toggleChildFromCache(workItem, childId, store),
      });
    },
    async undoChildRemoval(workItem, childId) {
      const { data } = await this.updateWorkItem(workItem, childId, this.issuableGid);

      if (data.workItemUpdate.errors.length === 0) {
        this.activeToast?.hide();
      }
    },
    async removeChild(childId) {
      const { data } = await this.updateWorkItem(null, childId, null);

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
  <div
    class="gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100 gl-bg-gray-10 gl-mt-4"
    data-testid="work-item-links"
  >
    <div
      class="gl-px-5 gl-py-3 gl-display-flex gl-justify-content-space-between"
      :class="{ 'gl-border-b-1 gl-border-b-solid gl-border-b-gray-100': isOpen }"
    >
      <div class="gl-display-flex gl-flex-grow-1">
        <h5 class="gl-m-0 gl-line-height-24">{{ $options.i18n.title }}</h5>
        <span
          class="gl-display-inline-flex gl-align-items-center gl-line-height-24 gl-ml-3"
          data-testid="children-count"
        >
          <gl-icon :name="$options.WIDGET_TYPE_TASK_ICON" class="gl-mr-2 gl-text-secondary" />
          {{ childrenCountLabel }}
        </span>
      </div>
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
      <div class="gl-border-l-1 gl-border-l-solid gl-border-l-gray-100 gl-pl-3 gl-ml-3">
        <gl-button
          category="tertiary"
          size="small"
          :icon="toggleIcon"
          :aria-label="toggleLabel"
          data-testid="toggle-links"
          @click="toggle"
        />
      </div>
    </div>
    <gl-alert v-if="error && !isLoading" variant="danger" @dismiss="error = undefined">
      {{ error }}
    </gl-alert>
    <div
      v-if="isOpen"
      class="gl-bg-gray-10 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
      :class="{ 'gl-p-5 gl-pb-3': !error }"
      data-testid="links-body"
    >
      <gl-loading-icon v-if="isLoading" color="dark" class="gl-my-3" />

      <template v-else>
        <div v-if="isChildrenEmpty && !isShownAddForm && !error" data-testid="links-empty">
          <p class="gl-mb-3">
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
          @addWorkItemChild="addChild"
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
          @workItemDeleted="handleWorkItemDeleted(activeChild.id)"
        />
      </template>
    </div>
  </div>
</template>
