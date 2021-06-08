<script>
import { GlDrawer } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import SidebarDropdownWidget from 'ee_else_ce/sidebar/components/sidebar_dropdown_widget.vue';
import BoardSidebarDueDate from '~/boards/components/sidebar/board_sidebar_due_date.vue';
import BoardSidebarLabelsSelect from '~/boards/components/sidebar/board_sidebar_labels_select.vue';
import BoardSidebarTimeTracker from '~/boards/components/sidebar/board_sidebar_time_tracker.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { ISSUABLE } from '~/boards/constants';
import { contentTop } from '~/lib/utils/common_utils';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';

export default {
  headerHeight: `${contentTop()}px`,
  components: {
    GlDrawer,
    BoardSidebarTitle,
    SidebarAssigneesWidget,
    SidebarConfidentialityWidget,
    BoardSidebarTimeTracker,
    BoardSidebarLabelsSelect,
    BoardSidebarDueDate,
    SidebarSubscriptionsWidget,
    SidebarDropdownWidget,
    BoardSidebarWeightInput: () =>
      import('ee_component/boards/components/sidebar/board_sidebar_weight_input.vue'),
  },
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
  },
  computed: {
    ...mapGetters([
      'isSidebarOpen',
      'activeBoardItem',
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
      return this.activeBoardItem?.referencePath?.split('#')[0] || '';
    },
  },
  methods: {
    ...mapActions(['toggleBoardItem', 'setAssignees', 'setActiveItemConfidential']),
    handleClose() {
      this.toggleBoardItem({ boardItem: this.activeBoardItem, sidebarType: this.sidebarType });
    },
  },
};
</script>

<template>
  <gl-drawer
    v-if="showSidebar"
    :open="isSidebarOpen"
    :header-height="$options.headerHeight"
    @close="handleClose"
  >
    <template #header>{{ __('Issue details') }}</template>
    <template #default>
      <board-sidebar-title />
      <sidebar-assignees-widget
        :iid="activeBoardItem.iid"
        :full-path="fullPath"
        :initial-assignees="activeBoardItem.assignees"
        :allow-multiple-assignees="multipleAssigneesFeatureAvailable"
        @assignees-updated="setAssignees"
      />
      <sidebar-dropdown-widget
        v-if="epicFeatureAvailable"
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
        <sidebar-dropdown-widget
          v-if="iterationFeatureAvailable"
          :iid="activeBoardItem.iid"
          issuable-attribute="iteration"
          :workspace-path="projectPathForActiveIssue"
          :attr-workspace-path="groupPathForActiveIssue"
          :issuable-type="issuableType"
          class="gl-mt-5"
          data-testid="iteration-edit"
          data-qa-selector="iteration_container"
        />
      </div>
      <board-sidebar-time-tracker class="swimlanes-sidebar-time-tracker" />
      <board-sidebar-due-date />
      <board-sidebar-labels-select class="labels" />
      <board-sidebar-weight-input v-if="weightFeatureAvailable" class="weight" />
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
</template>
