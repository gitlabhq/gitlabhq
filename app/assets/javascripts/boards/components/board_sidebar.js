// This is a true violation of @gitlab/no-runtime-template-compiler, as it
// relies on app/views/shared/boards/components/_sidebar.html.haml for its
// template.
/* eslint-disable no-new, @gitlab/no-runtime-template-compiler */

import { GlLabel } from '@gitlab/ui';
import $ from 'jquery';
import Vue from 'vue';
import DueDateSelectors from '~/due_date_select';
import IssuableContext from '~/issuable_context';
import LabelsSelect from '~/labels_select';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { sprintf, __ } from '~/locale';
import MilestoneSelect from '~/milestone_select';
import Sidebar from '~/right_sidebar';
import AssigneeTitle from '~/sidebar/components/assignees/assignee_title.vue';
import Assignees from '~/sidebar/components/assignees/assignees.vue';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import Subscriptions from '~/sidebar/components/subscriptions/subscriptions.vue';
import TimeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';
import eventHub from '~/sidebar/event_hub';
import boardsStore from '../stores/boards_store';

export default Vue.extend({
  components: {
    AssigneeTitle,
    Assignees,
    GlLabel,
    SidebarEpicsSelect: () =>
      import('ee_component/sidebar/components/sidebar_item_epics_select.vue'),
    Subscriptions,
    TimeTracker,
    SidebarAssigneesWidget,
  },
  props: {
    currentUser: {
      type: Object,
      default: () => ({}),
      required: false,
    },
  },
  data() {
    return {
      detail: boardsStore.detail,
      issue: {},
      list: {},
      loadingAssignees: false,
      timeTrackingLimitToHours: boardsStore.timeTracking.limitToHours,
    };
  },
  computed: {
    showSidebar() {
      return Object.keys(this.issue).length;
    },
    milestoneTitle() {
      return this.issue.milestone ? this.issue.milestone.title : __('No milestone');
    },
    canRemove() {
      return !this.list?.preset;
    },
    hasLabels() {
      return this.issue.labels && this.issue.labels.length;
    },
    labelDropdownTitle() {
      return this.hasLabels
        ? sprintf(__('%{firstLabel} +%{labelCount} more'), {
            firstLabel: this.issue.labels[0].title,
            labelCount: this.issue.labels.length - 1,
          })
        : __('Label');
    },
    selectedLabels() {
      return this.hasLabels ? this.issue.labels.map((l) => l.title).join(',') : '';
    },
  },
  watch: {
    detail: {
      handler() {
        if (this.issue.id !== this.detail.issue.id) {
          $('.js-issue-board-sidebar', this.$el).each((i, el) => {
            $(el).data('deprecatedJQueryDropdown').clearMenu();
          });
        }

        this.issue = this.detail.issue;
        this.list = this.detail.list;
      },
      deep: true,
    },
  },
  created() {
    eventHub.$on('sidebar.closeAll', this.closeSidebar);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.closeAll', this.closeSidebar);
  },
  mounted() {
    new IssuableContext(this.currentUser);
    new MilestoneSelect();
    new DueDateSelectors();
    new LabelsSelect();
    new Sidebar();
  },
  methods: {
    closeSidebar() {
      this.detail.issue = {};
    },
    setAssignees({ assignees }) {
      boardsStore.detail.issue.setAssignees(assignees);
    },
    showScopedLabels(label) {
      return boardsStore.scopedLabels.enabled && isScopedLabel(label);
    },
  },
});
