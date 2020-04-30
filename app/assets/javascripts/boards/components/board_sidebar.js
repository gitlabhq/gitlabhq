/* eslint-disable no-new */

import $ from 'jquery';
import Vue from 'vue';
import { GlLabel } from '@gitlab/ui';
import Flash from '~/flash';
import { sprintf, __ } from '~/locale';
import Sidebar from '~/right_sidebar';
import eventHub from '~/sidebar/event_hub';
import DueDateSelectors from '~/due_date_select';
import IssuableContext from '~/issuable_context';
import LabelsSelect from '~/labels_select';
import AssigneeTitle from '~/sidebar/components/assignees/assignee_title.vue';
import Assignees from '~/sidebar/components/assignees/assignees.vue';
import Subscriptions from '~/sidebar/components/subscriptions/subscriptions.vue';
import TimeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';
import MilestoneSelect from '~/milestone_select';
import RemoveBtn from './sidebar/remove_issue.vue';
import boardsStore from '../stores/boards_store';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default Vue.extend({
  components: {
    AssigneeTitle,
    Assignees,
    GlLabel,
    SidebarEpicsSelect: () =>
      import('ee_component/sidebar/components/sidebar_item_epics_select.vue'),
    RemoveBtn,
    Subscriptions,
    TimeTracker,
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
      return this.issue.milestone ? this.issue.milestone.title : __('No Milestone');
    },
    canRemove() {
      return !this.list.preset;
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
      return this.hasLabels ? this.issue.labels.map(l => l.title).join(',') : '';
    },
  },
  watch: {
    detail: {
      handler() {
        if (this.issue.id !== this.detail.issue.id) {
          $('.block.assignee')
            .find('input:not(.js-vue)[name="issue[assignee_ids][]"]')
            .each((i, el) => {
              $(el).remove();
            });

          $('.js-issue-board-sidebar', this.$el).each((i, el) => {
            $(el)
              .data('glDropdown')
              .clearMenu();
          });
        }

        this.issue = this.detail.issue;
        this.list = this.detail.list;
      },
      deep: true,
    },
  },
  created() {
    // Get events from glDropdown
    eventHub.$on('sidebar.removeAssignee', this.removeAssignee);
    eventHub.$on('sidebar.addAssignee', this.addAssignee);
    eventHub.$on('sidebar.removeAllAssignees', this.removeAllAssignees);
    eventHub.$on('sidebar.saveAssignees', this.saveAssignees);
    eventHub.$on('sidebar.closeAll', this.closeSidebar);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.removeAssignee', this.removeAssignee);
    eventHub.$off('sidebar.addAssignee', this.addAssignee);
    eventHub.$off('sidebar.removeAllAssignees', this.removeAllAssignees);
    eventHub.$off('sidebar.saveAssignees', this.saveAssignees);
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
    assignSelf() {
      // Notify gl dropdown that we are now assigning to current user
      this.$refs.assigneeBlock.dispatchEvent(new Event('assignYourself'));

      this.addAssignee(this.currentUser);
      this.saveAssignees();
    },
    removeAssignee(a) {
      boardsStore.detail.issue.removeAssignee(a);
    },
    addAssignee(a) {
      boardsStore.detail.issue.addAssignee(a);
    },
    removeAllAssignees() {
      boardsStore.detail.issue.removeAllAssignees();
    },
    saveAssignees() {
      this.loadingAssignees = true;

      boardsStore.detail.issue
        .update()
        .then(() => {
          this.loadingAssignees = false;
        })
        .catch(() => {
          this.loadingAssignees = false;
          Flash(__('An error occurred while saving assignees'));
        });
    },
    showScopedLabels(label) {
      return boardsStore.scopedLabels.enabled && isScopedLabel(label);
    },
  },
});
