/* global Vue */
/* global UsersSelect */
/* global MilestoneSelect */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.ModalFilters = Vue.extend({
    computed: {
      currentUsername() {
        return gon.current_username;
      },
    },
    mounted() {
      new UsersSelect();
      new MilestoneSelect();
    },
    template: `
      <div class="modal-filters">
        <div class="dropdown">
          <button
            class="dropdown-menu-toggle js-user-search js-author-search"
            type="button"
            data-toggle="dropdown"
            data-any-user="Any Author"
            data-current-user="true"
            data-field-name="author_id"
            :data-project-id="12"
            :data-first-user="currentUsername">
            Author
            <i class="fa fa-chevron-down"></i>
          </button>
          <div class="dropdown-menu dropdown-select dropdown-menu-user dropdown-menu-selectable dropdown-menu-author">
            <div class="dropdown-title">
              <span>Filter by author</span>
              <button
                class="dropdown-title-button dropdown-menu-close"
                aria-label="Close"
                type="button">
                <i class="fa fa-times dropdown-menu-close-icon"></i>
              </button>
            </div>
            <div class="dropdown-input">
              <input
                type="search"
                class="dropdown-input-field"
                placeholder="Search authors"
                autocomplete="off" />
              <i class="fa fa-search dropdown-input-search"></i>
              <i role="button" class="fa fa-times dropdown-input-clear js-dropdown-input-clear"></i>
            </div>
            <div class="dropdown-content"></div>
            <div class="dropdown-loading"><i class="fa fa-spinner fa-spin"></i></div>
          </div>
        </div>
        <div class="dropdown">
          <button
            class="dropdown-menu-toggle js-user-search js-assignee-search"
            type="button"
            data-toggle="dropdown"
            data-any-user="Any Assignee"
            data-null-user="true"
            data-current-user="true"
            data-field-name="assignee_id"
            :data-project-id="12"
            :data-first-user="currentUsername">
            Assignee
            <i class="fa fa-chevron-down"></i>
          </button>
          <div class="dropdown-menu dropdown-select dropdown-menu-user dropdown-menu-selectable dropdown-menu-author">
            <div class="dropdown-title">
              <span>Filter by assignee</span>
              <button
                class="dropdown-title-button dropdown-menu-close"
                aria-label="Close"
                type="button">
                <i class="fa fa-times dropdown-menu-close-icon"></i>
              </button>
            </div>
            <div class="dropdown-input">
              <input
                type="search"
                class="dropdown-input-field"
                placeholder="Search assignee"
                autocomplete="off" />
              <i class="fa fa-search dropdown-input-search"></i>
              <i role="button" class="fa fa-times dropdown-input-clear js-dropdown-input-clear"></i>
            </div>
            <div class="dropdown-content"></div>
            <div class="dropdown-loading"><i class="fa fa-spinner fa-spin"></i></div>
          </div>
        </div>
        <div class="dropdown">
          <button
            class="dropdown-menu-toggle js-milestone-select"
            type="button"
            data-toggle="dropdown"
            data-show-any="true"
            data-show-upcoming="true"
            data-field-name="milestone_title"
            :data-project-id="12"
            :data-milestones="'/root/test/milestones.json'">
            Milestone
            <i class="fa fa-chevron-down"></i>
          </button>
          <div class="dropdown-menu dropdown-select dropdown-menu-selectable dropdown-menu-milestone">
            <div class="dropdown-title">
              <span>Filter by milestone</span>
              <button
                class="dropdown-title-button dropdown-menu-close"
                aria-label="Close"
                type="button">
                <i class="fa fa-times dropdown-menu-close-icon"></i>
              </button>
            </div>
            <div class="dropdown-input">
              <input
                type="search"
                class="dropdown-input-field"
                placeholder="Search milestones"
                autocomplete="off" />
              <i class="fa fa-search dropdown-input-search"></i>
              <i role="button" class="fa fa-times dropdown-input-clear js-dropdown-input-clear"></i>
            </div>
            <div class="dropdown-content"></div>
            <div class="dropdown-loading"><i class="fa fa-spinner fa-spin"></i></div>
          </div>
        </div>
        <div class="dropdown">
          <button
            class="dropdown-menu-toggle js-label-select js-multiselect"
            type="button"
            data-toggle="dropdown">
            Label
            <i class="fa fa-chevron-down"></i>
          </button>
        </div>
      </div>
    `,
  });
})();
