<script>
import { GlDrawer } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { mapState, mapActions, mapGetters } from 'vuex';
import SidebarDropdownWidget from 'ee_else_ce/sidebar/components/sidebar_dropdown_widget.vue';
import { __, sprintf } from '~/locale';
import BoardSidebarTimeTracker from '~/boards/components/sidebar/board_sidebar_time_tracker.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { BoardType, ISSUABLE, INCIDENT, issuableTypes } from '~/boards/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarSeverity from '~/sidebar/components/severity/sidebar_severity.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SidebarLabelsWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import { LabelType } from '~/sidebar/components/labels/labels_select_widget/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlDrawer,
    BoardSidebarTitle,
    SidebarAssigneesWidget,
    SidebarDateWidget,
    SidebarConfidentialityWidget,
    BoardSidebarTimeTracker,
    SidebarLabelsWidget,
    SidebarSubscriptionsWidget,
    SidebarDropdownWidget,
    SidebarTodoWidget,
    SidebarSeverity,
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
      default: issuableTypes.issue,
    },
    isGroupBoard: {
      default: false,
    },
  },
  inheritAttrs: false,
  computed: {
    ...mapGetters([
      'isSidebarOpen',
      'activeBoardItem',
      'groupPathForActiveIssue',
      'projectPathForActiveIssue',
    ]),
    ...mapState(['sidebarType']),
    isIssuableSidebar() {
      return this.sidebarType === ISSUABLE;
    },
    isIncidentSidebar() {
      return this.activeBoardItem.type === INCIDENT;
    },
    showSidebar() {
      return this.isIssuableSidebar && this.isSidebarOpen;
    },
    sidebarTitle() {
      return this.isIncidentSidebar ? __('Incident details') : __('Issue details');
    },
    fullPath() {
      return this.activeBoardItem?.referencePath?.split('#')[0] || '';
    },
    parentType() {
      return this.isGroupBoard ? BoardType.group : BoardType.project;
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
      return this.isGroupBoard ? LabelType.group : LabelType.project;
    },
    labelsFilterPath() {
      return this.isGroupBoard
        ? this.labelsFilterBasePath.replace(':project_path', this.projectPathForActiveIssue)
        : this.labelsFilterBasePath;
    },
  },
  methods: {
    ...mapActions([
      'toggleBoardItem',
      'setAssignees',
      'setActiveItemConfidential',
      'setActiveBoardItemLabels',
      'setActiveItemWeight',
      'setActiveItemHealthStatus',
    ]),
    handleClose() {
      this.toggleBoardItem({ boardItem: this.activeBoardItem, sidebarType: this.sidebarType });
    },
    handleUpdateSelectedLabels({ labels, id }) {
      this.setActiveBoardItemLabels({
        id,
        projectPath: this.projectPathForActiveIssue,
        labelIds: labels.map((label) => getIdFromGraphQLId(label.id)),
        labels,
      });
    },
    handleLabelRemove(removeLabelId) {
      this.setActiveBoardItemLabels({
        iid: this.activeBoardItem.iid,
        projectPath: this.projectPathForActiveIssue,
        removeLabelIds: [removeLabelId],
      });
    },
  },
};
</script>

<template>
  <mounting-portal mount-to="#js-right-sidebar-portal" name="board-content-sidebar" append>
    <gl-drawer
      v-bind="$attrs"
      :open="showSidebar"
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
          :issuable-id="activeBoardItem.id"
          :issuable-iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
        />
      </template>
      <template #default>
        <board-sidebar-title />
        <sidebar-assignees-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :initial-assignees="activeBoardItem.assignees"
          :allow-multiple-assignees="multipleAssigneesFeatureAvailable"
          :editable="canUpdate"
          @assignees-updated="setAssignees"
        />
        <sidebar-dropdown-widget
          v-if="epicFeatureAvailable && !isIncidentSidebar"
          :iid="activeBoardItem.iid"
          issuable-attribute="epic"
          :workspace-path="projectPathForActiveIssue"
          :attr-workspace-path="groupPathForActiveIssue"
          :issuable-type="issuableType"
          data-testid="sidebar-epic"
        />
        <div>
          <sidebar-dropdown-widget
            :iid="activeBoardItem.iid"
            issuable-attribute="milestone"
            :workspace-path="projectPathForActiveIssue"
            :attr-workspace-path="projectPathForActiveIssue"
            :issuable-type="issuableType"
            data-testid="sidebar-milestones"
          />
          <sidebar-iteration-widget
            v-if="iterationFeatureAvailable && !isIncidentSidebar"
            :iid="activeBoardItem.iid"
            :workspace-path="projectPathForActiveIssue"
            :attr-workspace-path="groupPathForActiveIssue"
            :issuable-type="issuableType"
            class="gl-mt-5"
            data-testid="iteration-edit"
          />
        </div>
        <board-sidebar-time-tracker />
        <sidebar-date-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          data-testid="sidebar-due-date"
        />
        <sidebar-labels-widget
          class="block labels"
          :iid="activeBoardItem.iid"
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
          @onLabelRemove="handleLabelRemove"
          @updateSelectedLabels="handleUpdateSelectedLabels"
        >
          {{ __('None') }}
        </sidebar-labels-widget>
        <sidebar-severity
          v-if="isIncidentSidebar"
          :iid="activeBoardItem.iid"
          :project-path="fullPath"
          :initial-severity="activeBoardItem.severity"
        />
        <sidebar-weight-widget
          v-if="weightFeatureAvailable && !isIncidentSidebar"
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          @weightUpdated="setActiveItemWeight($event)"
        />
        <sidebar-health-status-widget
          v-if="healthStatusFeatureAvailable"
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          @statusUpdated="setActiveItemHealthStatus($event)"
        />
        <sidebar-confidentiality-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          @confidentialityUpdated="setActiveItemConfidential($event)"
        />
        <sidebar-subscriptions-widget
          :iid="activeBoardItem.iid"
          :full-path="fullPath"
          :issuable-type="issuableType"
          data-testid="sidebar-notifications"
        />
      </template>
    </gl-drawer>
  </mounting-portal>
</template>
