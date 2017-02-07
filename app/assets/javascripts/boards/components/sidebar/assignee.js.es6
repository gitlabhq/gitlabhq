/*= require vue_common_component/bs_dropdown_menu */
/* global Vue */

require('../../../vue_common_component/bs_dropdown_menu');

(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardsSidebarAssignee = Vue.extend({
    template: `
      <div class="block assignee">
        <div class="title hide-collapsed">
          Assignee
          <i
            class="fa fa-spinner fa-spin block-loading"
            v-if="canAdminIssue"></i>
          <a
            class="edit-link pull-right"
            href="#"
            v-if="canAdminIssue">
            Edit
          </a>
        </div>
        <div class="value hide-collapsed">
          <span
            class="assign-yourself no-value"
            v-if="!issue.assignee">
            No assignee
            <span v-if="canAdminIssue">
              -
              <a
                class="js-assign-yourself"
                href="#">
                assign yourself
              </a>
            </span>
          </span>
          <a
            class="author_link bold"
            :href="assigneeUrl"
            v-if="issue.assignee">
            <img
              class="avatar avatar-inline s32"
              :src="issue.assignee.avatar"
              width="32"
              alt="Avatar" />
            <span class="author">
              {{ issue.assignee.name }}
            </span>
            <span class="username">
              {{ issue.assignee.reference }}
            </span>
          </a>
        </div>
        <div class="selectbox hide-collapsed">
          <input
            type="hidden"
            name="issue[assignee_id]"
            id="issue_assignee_id"
            :value="issue.assignee.id"
            v-if="issue.assignee" />
          <div class="dropdown">
            <button
              class="dropdown-menu-toggle js-user-search js-author-search js-issue-board-sidebar"
              type="button"
              data-toggle="dropdown"
              data-field-name="issue[assignee_id]"
              :data-first-user="currentUsername"
              data-current-user="true"
              :data-project-id="projectId"
              data-null-user="true"
              :data-issuable-id="issue.id"
              :data-issue-update="issueLinkBase + '/' + issue.id + '.json'">
              Select assignee
              <i class="fa fa-chevron-down"></i>
            </button>
            <bs-dropdown-menu
              title="Assign to"
              :filter="true"
              :selectable="true"
              filter-placeholder="Search uers"
              class-names="dropdown-menu-user dropdown-menu-author"></bs-dropdown-menu>
          </div>
        </div>
      </div>
    `,
    props: [
      'currentUser', 'canAdminIssue', 'issue', 'issueLinkBase', 'projectId',
    ],
    computed: {
      assigneeUrl() {
        return `${gon.relative_url_root}/${this.issue.assignee.username}`
      },
      currentUsername() {
        return this.currentUser.username || false;
      },
    },
  });
})();
