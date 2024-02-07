<script>
import { GlDrawer } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import SidebarDropdownWidget from 'ee_else_ce/sidebar/components/sidebar_dropdown_widget.vue';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import setActiveBoardItemMutation from 'ee_else_ce/boards/graphql/client/set_active_board_item.mutation.graphql';
import { __, s__, sprintf } from '~/locale';
import SidebarTimeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { INCIDENT } from '~/boards/constants';
import { TYPE_ISSUE, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarSeverityWidget from '~/sidebar/components/severity/sidebar_severity_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SidebarLabelsWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { setError, updateListWeightCache } from '../graphql/cache_updates';

export default {
  components: {
    GlDrawer,
    BoardSidebarTitle,
    SidebarAssigneesWidget,
    SidebarDateWidget,
    SidebarConfidentialityWidget,
    SidebarTimeTracker,
    SidebarLabelsWidget,
    SidebarSubscriptionsWidget,
    SidebarDropdownWidget,
    SidebarTodoWidget,
    SidebarSeverityWidget,
    MountingPortal,
    SidebarHealthStatusWidget: () =>
      import('ee_component/sidebar/components/health_status/sidebar_health_status_widget.vue'),
    SidebarIterationWidget: () =>
      import('ee_component/sidebar/components/iteration/sidebar_iteration_widget.vue'),
    SidebarWeightWidget: () =>
      import('ee_component/sidebar/components/weight/sidebar_weight_widget.vue'),
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    multipleAssigneesFeatureAvailable: {
      default: false,
    },
    epicFeatureAvailable: {
      default: false,
    },
    iterationFeatureAvailable: {
      default: false,
    },
    weightFeatureAvailable: {
      default: false,
    },
    healthStatusFeatureAvailable: {
      default: false,
    },
    allowLabelEdit: {
      default: false,
    },
    labelsFilterBasePath: {
      default: '',
    },
    canUpdate: {
      default: false,
    },
    issuableType: {
      default: TYPE_ISSUE,
    },
    isGroupBoard: {
      default: false,
    },
    timeTrackingLimitToHours: {
      default: false,
    },
  },
  inheritAttrs: false,
  apollo: {
    activeBoardCard: {
      query: activeBoardItemQuery,
      variables: {
        isIssue: true,
      },
      update(data) {
        if (!data.activeBoardItem?.id) {
          return { id: '', iid: '' };
        }
        return {
          ...data.activeBoardItem,
          assignees: data.activeBoardItem.assignees?.nodes || [],
        };
      },
      error(error) {
        setError({
          error,
          message: s__('Boards|An error occurred while selecting the card. Please try again.'),
        });
      },
    },
  },
  computed: {
    activeBoardIssuable() {
      return this.activeBoardCard;
    },
    isSidebarOpen() {
      return Boolean(this.activeBoardIssuable?.id);
    },
    isIncidentSidebar() {
      return this.activeBoardIssuable?.type === INCIDENT;
    },
    sidebarTitle() {
      return this.isIncidentSidebar ? __('Incident details') : __('Issue details');
    },
    parentType() {
      return this.isGroupBoard ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
    createLabelTitle() {
      return sprintf(__('Create %{workspace} label'), {
        workspace: this.parentType,
      });
    },
    manageLabelTitle() {
      return sprintf(__('Manage %{workspace} labels'), {
        workspace: this.parentType,
      });
    },
    attrWorkspacePath() {
      return this.isGroupBoard ? this.groupPathForActiveIssue : this.projectPathForActiveIssue;
    },
    labelType() {
      return this.isGroupBoard ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
    labelsFilterPath() {
      return this.isGroupBoard
        ? this.labelsFilterBasePath.replace(':project_path', this.projectPathForActiveIssue)
        : this.labelsFilterBasePath;
    },
    groupPathForActiveIssue() {
      const { referencePath = '' } = this.activeBoardIssuable;
      return referencePath.slice(0, referencePath.lastIndexOf('/'));
    },
    projectPathForActiveIssue() {
      const { referencePath = '' } = this.activeBoardIssuable;
      return referencePath.slice(0, referencePath.indexOf('#'));
    },
    showWorkItemEpics() {
      return this.glFeatures.displayWorkItemEpicIssueSidebar;
    },
    showEpicSidebarDropdownWidget() {
      return this.epicFeatureAvailable && !this.isIncidentSidebar && this.activeBoardIssuable.id;
    },
    showIterationSidebarDropdownWidget() {
      return (
        this.iterationFeatureAvailable && !this.isIncidentSidebar && this.activeBoardIssuable.id
      );
    },
  },
  methods: {
    handleClose() {
      this.$apollo.mutate({
        mutation: setActiveBoardItemMutation,
        variables: {
          boardItem: null,
          listId: null,
        },
      });
    },
    updateListTotalWeight({ weight }) {
      const { cache } = this.$apollo.provider.clients.defaultClient;
      updateListWeightCache({ weight, listId: this.activeBoardCard.listId, cache });
    },
  },
};
</script>

<template>
  <mounting-portal mount-to="#js-right-sidebar-portal" name="board-content-sidebar" append>
    <gl-drawer
      v-bind="$attrs"
      :open="isSidebarOpen"
      class="boards-sidebar"
      variant="sidebar"
      @close="handleClose"
    >
      <template #title>
        <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">{{ sidebarTitle }}</h2>
      </template>
      <template #header>
        <sidebar-todo-widget
          class="gl-mt-3"
          :issuable-id="activeBoardIssuable.id"
          :issuable-iid="activeBoardIssuable.iid"
          :full-path="projectPathForActiveIssue"
          :issuable-type="issuableType"
        />
      </template>
      <template #default>
        <board-sidebar-title :active-item="activeBoardIssuable" data-testid="sidebar-title" />
        <sidebar-assignees-widget
          v-if="activeBoardIssuable.assignees"
          :iid="activeBoardIssuable.iid"
          :full-path="projectPathForActiveIssue"
          :initial-assignees="activeBoardIssuable.assignees"
          :allow-multiple-assignees="multipleAssigneesFeatureAvailable"
          :editable="canUpdate"
        />
        <sidebar-dropdown-widget
          v-if="showEpicSidebarDropdownWidget"
          :key="`epic-${activeBoardIssuable.iid}`"
          :iid="activeBoardIssuable.iid"
          issuable-attribute="epic"
          :workspace-path="projectPathForActiveIssue"
          :attr-workspace-path="groupPathForActiveIssue"
          :issuable-type="issuableType"
          :issue-id="activeBoardIssuable.id"
          :show-work-item-epics="showWorkItemEpics"
          data-testid="sidebar-epic"
        />
        <div>
          <sidebar-dropdown-widget
            v-if="activeBoardIssuable.id"
            :key="`milestone-${activeBoardIssuable.iid}`"
            :iid="activeBoardIssuable.iid"
            issuable-attribute="milestone"
            :workspace-path="projectPathForActiveIssue"
            :attr-workspace-path="projectPathForActiveIssue"
            :issuable-type="issuableType"
            :issue-id="activeBoardIssuable.id"
            data-testid="sidebar-milestones"
          />
          <sidebar-iteration-widget
            v-if="showIterationSidebarDropdownWidget"
            :key="`iteration-${activeBoardIssuable.iid}`"
            :iid="activeBoardIssuable.iid"
            :issue-id="activeBoardIssuable.id"
            :workspace-path="projectPathForActiveIssue"
            :attr-workspace-path="groupPathForActiveIssue"
            :issuable-type="issuableType"
            class="gl-mt-5"
            data-testid="iteration-edit"
          />
        </div>
        <sidebar-time-tracker
          :can-add-time-entries="canUpdate"
          :can-set-time-estimate="canUpdate"
          :full-path="projectPathForActiveIssue"
          :issuable-id="activeBoardIssuable.id"
          :issuable-iid="activeBoardIssuable.iid"
          :limit-to-hours="timeTrackingLimitToHours"
          :show-collapsed="false"
        />
        <sidebar-date-widget
          :iid="activeBoardIssuable.iid"
          :full-path="projectPathForActiveIssue"
          :issuable-type="issuableType"
          data-testid="sidebar-due-date"
        />
        <sidebar-labels-widget
          class="block labels"
          :iid="activeBoardIssuable.iid"
          :full-path="projectPathForActiveIssue"
          :allow-label-remove="allowLabelEdit"
          :allow-multiselect="true"
          :footer-create-label-title="createLabelTitle"
          :footer-manage-label-title="manageLabelTitle"
          :labels-create-title="createLabelTitle"
          :labels-filter-base-path="labelsFilterPath"
          :attr-workspace-path="attrWorkspacePath"
          workspace-type="project"
          :issuable-type="issuableType"
          :label-create-type="labelType"
        >
          {{ __('None') }}
        </sidebar-labels-widget>
        <sidebar-severity-widget
          v-if="isIncidentSidebar"
          :iid="activeBoardIssuable.iid"
          :project-path="projectPathForActiveIssue"
          :initial-severity="activeBoardIssuable.severity"
        />
        <sidebar-weight-widget
          v-if="weightFeatureAvailable && !isIncidentSidebar"
          :iid="activeBoardIssuable.iid"
          :full-path="projectPathForActiveIssue"
          :issuable-type="issuableType"
          @weightUpdated="updateListTotalWeight"
        />
        <sidebar-health-status-widget
          v-if="healthStatusFeatureAvailable"
          :iid="activeBoardIssuable.iid"
          :full-path="projectPathForActiveIssue"
          :issuable-type="issuableType"
        />
        <sidebar-confidentiality-widget
          :iid="activeBoardIssuable.iid"
          :full-path="projectPathForActiveIssue"
          :issuable-type="issuableType"
        />
        <sidebar-subscriptions-widget
          :iid="activeBoardIssuable.iid"
          :full-path="projectPathForActiveIssue"
          :issuable-type="issuableType"
          :show-in-dropdown="false"
          data-testid="sidebar-notifications"
        />
      </template>
    </gl-drawer>
  </mounting-portal>
</template>
