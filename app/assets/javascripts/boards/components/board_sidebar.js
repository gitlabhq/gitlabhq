/* eslint-disable comma-dangle, space-before-function-paren, no-new */
/* global IssuableContext */
/* global MilestoneSelect */
/* global LabelsSelect */
/* global Sidebar */

import Vue from 'vue';
import eventHub from '../../sidebar/event_hub';

import AssigneeTitle from '../../sidebar/components/assignees/assignee_title';
import Assignees from '../../sidebar/components/assignees/assignees';

require('./sidebar/remove_issue');

(() => {
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
      }
    },
    watch: {
      detail: {
        handler () {
          if (this.issue.id !== this.detail.issue.id) {
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
      issue () {
        if (this.showSidebar) {
          this.$nextTick(() => {
            $('.right-sidebar').getNiceScroll(0).doScrollTop(0, 0);
            $('.right-sidebar').getNiceScroll().resize();
          });
        }
      }
    },
    methods: {
      closeSidebar () {
        this.detail.issue = {};
      },
      assignSelf () {
        // Notify gl dropdown that we are now assigning to current user
        this.$refs.assigneeBlock.dispatchEvent(new Event('assignYourself'));

        this.addUser(this.currentUser.id);
        this.saveUsers();
      },
      removeUser (id) {
        gl.issueBoards.BoardsStore.detail.issue.removeUserId(id);
      },
      addUser (id) {
        gl.issueBoards.BoardsStore.detail.issue.addUserId(id);
      },
      removeAllUsers () {
        gl.issueBoards.BoardsStore.detail.issue.removeAllUserIds();
      },
      saveUsers () {
        this.loadingAssignees = true;

        gl.issueBoards.BoardsStore.detail.issue.update(this.endpoint)
          .then((response) => {
            this.loadingAssignees = false;

            const data = response.json();

            this.$forceUpdate();

            gl.issueBoards.BoardsStore.detail.issue.processAssignees(data.assignees);
          })
          .catch(() => {
            this.loadingAssignees = false;
            return new Flash('An error occurred while saving assignees');
          });
      },
    },
    created () {
      // Get events from glDropdown
      eventHub.$on('sidebar.removeUser', this.removeUser);
      eventHub.$on('sidebar.addUser', this.addUser);
      eventHub.$on('sidebar.removeAllUsers', this.removeAllUsers);
      eventHub.$on('sidebar.saveUsers', this.saveUsers);
    },
    beforeDestroy() {
      eventHub.$off('sidebar.removeUser', this.removeUser);
      eventHub.$off('sidebar.addUser', this.addUser);
      eventHub.$off('sidebar.removeAllUsers', this.removeAllUsers);
      eventHub.$off('sidebar.saveUsers', this.saveUsers);
    },
    mounted () {
      new IssuableContext(this.currentUser);
      new MilestoneSelect();
      new gl.DueDateSelectors();
      new LabelsSelect();
      new Sidebar();
      gl.Subscription.bindAll('.subscription');
    },
    components: {
      removeBtn: gl.issueBoards.RemoveIssueBtn,
      'assignee-title': AssigneeTitle,
      assignees: Assignees,
    },
  });
})();
