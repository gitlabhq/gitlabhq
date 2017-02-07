/* global Vue */
const userFilter = require('./filters/user');
const milestoneFilter = require('./filters/milestone');
const labelFilter = require('./filters/label');

module.exports = Vue.extend({
  name: 'modal-filters',
  props: {
    projectId: {
      type: Number,
      required: true,
    },
    milestonePath: {
      type: String,
      required: true,
    },
    labelPath: {
      type: String,
      required: true,
    },
  },
  destroyed() {
    gl.issueBoards.ModalStore.setDefaultFilter();
  },
  components: {
    userFilter,
    milestoneFilter,
    labelFilter,
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
      <milestone-filter :milestone-path="milestonePath"></milestone-filter>
      <label-filter :label-path="labelPath"></label-filter>
    </div>
  `,
});
