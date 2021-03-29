<script>
import { GlDrawer } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import BoardSidebarDueDate from '~/boards/components/sidebar/board_sidebar_due_date.vue';
import BoardSidebarIssueTitle from '~/boards/components/sidebar/board_sidebar_issue_title.vue';
import BoardSidebarLabelsSelect from '~/boards/components/sidebar/board_sidebar_labels_select.vue';
import BoardSidebarMilestoneSelect from '~/boards/components/sidebar/board_sidebar_milestone_select.vue';
import BoardSidebarSubscription from '~/boards/components/sidebar/board_sidebar_subscription.vue';
import BoardSidebarTimeTracker from '~/boards/components/sidebar/board_sidebar_time_tracker.vue';
import { ISSUABLE } from '~/boards/constants';
import { contentTop } from '~/lib/utils/common_utils';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  headerHeight: `${contentTop()}px`,
  components: {
    GlDrawer,
    BoardSidebarIssueTitle,
    SidebarAssigneesWidget,
    BoardSidebarTimeTracker,
    BoardSidebarLabelsSelect,
    BoardSidebarDueDate,
    BoardSidebarSubscription,
    BoardSidebarMilestoneSelect,
    BoardSidebarEpicSelect: () =>
      import('ee_component/boards/components/sidebar/board_sidebar_epic_select.vue'),
    BoardSidebarWeightInput: () =>
      import('ee_component/boards/components/sidebar/board_sidebar_weight_input.vue'),
    SidebarIterationWidget: () =>
      import('ee_component/sidebar/components/sidebar_iteration_widget.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters([
      'isSidebarOpen',
      'activeIssue',
      'groupPathForActiveIssue',
      'projectPathForActiveIssue',
    ]),
    ...mapState(['sidebarType', 'issuableType']),
    isIssuableSidebar() {
      return this.sidebarType === ISSUABLE;
    },
    showSidebar() {
      return this.isIssuableSidebar && this.isSidebarOpen;
    },
    fullPath() {
      return this.activeIssue?.referencePath?.split('#')[0] || '';
    },
  },
  methods: {
    ...mapActions(['toggleBoardItem', 'setAssignees']),
    handleClose() {
      this.toggleBoardItem({ boardItem: this.activeIssue, sidebarType: this.sidebarType });
    },
  },
};
</script>

<template>
  <gl-drawer
    v-if="showSidebar"
    data-testid="sidebar-drawer"
    :open="isSidebarOpen"
    :header-height="$options.headerHeight"
    @close="handleClose"
  >
    <template #header>{{ __('Issue details') }}</template>
    <template #default>
      <board-sidebar-issue-title />
      <sidebar-assignees-widget
        :iid="activeIssue.iid"
        :full-path="fullPath"
        :initial-assignees="activeIssue.assignees"
        class="assignee"
        @assignees-updated="setAssignees"
      />
      <board-sidebar-epic-select class="epic" />
      <div>
        <board-sidebar-milestone-select />
        <sidebar-iteration-widget
          :iid="activeIssue.iid"
          :workspace-path="projectPathForActiveIssue"
          :iterations-workspace-path="groupPathForActiveIssue"
          :issuable-type="issuableType"
          class="gl-mt-5"
        />
      </div>
      <board-sidebar-time-tracker class="swimlanes-sidebar-time-tracker" />
      <board-sidebar-due-date />
      <board-sidebar-labels-select class="labels" />
      <board-sidebar-weight-input v-if="glFeatures.issueWeights" class="weight" />
      <board-sidebar-subscription class="subscriptions" />
    </template>
  </gl-drawer>
</template>
