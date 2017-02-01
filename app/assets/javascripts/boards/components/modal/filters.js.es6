/* global Vue */
//= require_tree ./filters
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.ModalFilters = Vue.extend({
    props: {
      projectId: {
        type: Number,
        required: true,
      },
    },
    components: {
      'user-filter': gl.issueBoards.ModalFilterUser,
      'milestone-filter': gl.issueBoards.ModalFilterMilestone,
      'label-filter': gl.issueBoards.ModalLabelFilter,
    },
    template: `
      <div class="modal-filters">
        <user-filter
          dropdown-class-name="dropdown-menu-author"
          toggle-class-name="js-user-search js-author-search"
          toggle-label="Author"
          field-name="author_id"
          :project-id="projectId"></user-filter>
        <user-filter
          dropdown-class-name="dropdown-menu-author"
          toggle-class-name="js-assignee-search"
          toggle-label="Assignee"
          field-name="assignee_id"
          :null-user="true"
          :project-id="projectId"></user-filter>
        <milestone-filter></milestone-filter>
        <label-filter></label-filter>
      </div>
    `,
  });
})();
