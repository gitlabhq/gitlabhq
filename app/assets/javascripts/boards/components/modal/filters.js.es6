/* global Vue */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.ModalFilters = Vue.extend({
    template: `
      <div class="modal-filters">
        <div class="dropdown">
          <button
            class="dropdown-menu-toggle js-user-search js-author-search"
            type="button"
            data-toggle="dropdown">
            Author
            <i class="fa fa-chevron-down"></i>
          </button>
        </div>
        <div class="dropdown">
          <button
            class="dropdown-menu-toggle js-user-search js-assignee-search"
            type="button"
            data-toggle="dropdown">
            Assignee
            <i class="fa fa-chevron-down"></i>
          </button>
        </div>
        <div class="dropdown">
          <button
            class="dropdown-menu-toggle js-milestone-select"
            type="button"
            data-toggle="dropdown">
            Milestone
            <i class="fa fa-chevron-down"></i>
          </button>
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
