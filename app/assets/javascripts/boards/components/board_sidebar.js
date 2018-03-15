/* eslint-disable comma-dangle, space-before-function-paren, no-new */

import $ from 'jquery';
import Vue from 'vue';
import weight from 'ee/sidebar/components/weight/weight.vue';
import Flash from '../../flash';
import { __ } from '../../locale';
import Sidebar from '../../right_sidebar';
import eventHub from '../../sidebar/event_hub';
import assigneeTitle from '../../sidebar/components/assignees/assignee_title.vue';
import assignees from '../../sidebar/components/assignees/assignees.vue';
import DueDateSelectors from '../../due_date_select';
import './sidebar/remove_issue';
import IssuableContext from '../../issuable_context';
import LabelsSelect from '../../labels_select';
import subscriptions from '../../sidebar/components/subscriptions/subscriptions.vue';
import MilestoneSelect from '../../milestone_select';

const Store = gl.issueBoards.BoardsStore;

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

gl.issueBoards.BoardSidebar = Vue.extend({
  props: {
    currentUser: Object
  },
  data() {
    return {
      detail: Store.detail,
      issue: {},
      list: {},
      loadingAssignees: false,
    };
  },
  computed: {
    showSidebar () {
      return Object.keys(this.issue).length;
    },
    milestoneTitle() {
      return this.issue.milestone ? this.issue.milestone.title : 'No Milestone';
    },
    canRemove() {
      return !this.list.preset;
    },
  },
  watch: {
    detail: {
      handler () {
        if (this.issue.id !== this.detail.issue.id) {
          $('.block.assignee')
            .find('input:not(.js-vue)[name="issue[assignee_ids][]"]')
            .each((i, el) => {
              $(el).remove();
            });

          $('.js-issue-board-sidebar', this.$el).each((i, el) => {
            $(el).data('glDropdown').clearMenu();
          });
        }

        this.issue = this.detail.issue;
        this.list = this.detail.list;

        this.$nextTick(() => {
          this.endpoint = this.$refs.assigneeDropdown.dataset.issueUpdate;
        });
      },
      deep: true
    },
  },
  methods: {
    closeSidebar () {
      this.detail.issue = {};
    },
    assignSelf () {
      // Notify gl dropdown that we are now assigning to current user
      this.$refs.assigneeBlock.dispatchEvent(new Event('assignYourself'));

      this.addAssignee(this.currentUser);
      this.saveAssignees();
    },
    removeAssignee (a) {
      gl.issueBoards.BoardsStore.detail.issue.removeAssignee(a);
    },
    addAssignee (a) {
      gl.issueBoards.BoardsStore.detail.issue.addAssignee(a);
    },
    removeAllAssignees () {
      gl.issueBoards.BoardsStore.detail.issue.removeAllAssignees();
    },
    saveAssignees () {
      this.loadingAssignees = true;

      gl.issueBoards.BoardsStore.detail.issue.update(this.endpoint)
        .then(() => {
          this.loadingAssignees = false;
        })
        .catch(() => {
          this.loadingAssignees = false;
          Flash(__('An error occurred while saving assignees'));
        });
    },
  },
  created () {
    // Get events from glDropdown
    eventHub.$on('sidebar.removeAssignee', this.removeAssignee);
    eventHub.$on('sidebar.addAssignee', this.addAssignee);
    eventHub.$on('sidebar.removeAllAssignees', this.removeAllAssignees);
    eventHub.$on('sidebar.saveAssignees', this.saveAssignees);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.removeAssignee', this.removeAssignee);
    eventHub.$off('sidebar.addAssignee', this.addAssignee);
    eventHub.$off('sidebar.removeAllAssignees', this.removeAllAssignees);
    eventHub.$off('sidebar.saveAssignees', this.saveAssignees);
  },
  mounted () {
    new IssuableContext(this.currentUser);
    new MilestoneSelect();
    new DueDateSelectors();
    new LabelsSelect();
    new Sidebar();
  },
  components: {
    assigneeTitle,
    assignees,
    removeBtn: gl.issueBoards.RemoveIssueBtn,
    subscriptions,
    weight,
  },
});
