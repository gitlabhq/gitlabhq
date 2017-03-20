export default {
  name: 'AssigneeTitle',
  props: {
    numberOfAssignees: { type: Number, required: true },
  },
  computed: {
    hasMultipleAssignees() {
      return this.numberOfAssignees > 1;
    }
  },
  template: `
    <div class="title hide-collapsed">
      <template v-if="hasMultipleAssignees">
        {{numberOfAssignees}} Assignees
      </template>
      <template v-else>
        Assignee
      </template>
      <i aria-hidden="true" class="fa fa-spinner fa-spin block-loading" style="display: none;"></i>
      <a class="edit-link pull-right" href="#">Edit</a>
    </div>
  `,
};
