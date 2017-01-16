/* eslint-disable comma-dangle, space-before-function-paren, no-new */
/* global Vue */
/* global IssuableContext */
/* global MilestoneSelect */
/* global LabelsSelect */
/* global Sidebar */

require('./sidebar/remove_issue');
require('./sidebar/assignee');

(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardSidebar = Vue.extend({
    template: `
      <transition name="boards-sidebar-slide">
        <aside
          class="right-sidebar right-sidebar-expanded issue-boards-sidebar"
          v-show="showSidebar">
          <div class="issuable-sidebar">
            <div class="block issuable-sidebar-header">
              <span class="issuable-header-text hide-collapsed pull-left">
                <strong>
                  {{ issue.title }}
                </strong>
                <br />
                {{ issue.reference }}
              </span>
              <a
                class="gutter-toggle pull-right"
                role="button"
                href="#"
                @click.prevent="closeSidebar"
                aria-label="Toggle sidebar"
                v-html="closeIconHtml">
              </a>
            </div>
            <div class="js-issuable-update">
              <boards-sidebar-assignee
                :current-user="currentUser"
                :can-admin-issue="canAdminIssue"
                :issue="issue"
                :issue-link-base="issueLinkBase"
                :project-id="projectId">
              </boards-sidebar-assignee>
            </div>
          </div>
        </aside>
      </transition>
    `,
    components: {
      'boards-sidebar-assignee': gl.issueBoards.BoardsSidebarAssignee,
    },
    props: [
      'currentUser', 'closeIconHtml', 'canAdminIssue', 'issueLinkBase', 'projectId',
    ],
    data() {
      return {
        detail: Store.detail,
        issue: {},
        list: {},
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
      }
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
    },
  });
})();
