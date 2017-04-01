export default {
  name: 'AssigneeTitle',
  props: {
    loading: {
      type: Boolean,
      required: true
    },
    numberOfAssignees: {
      type: Number,
      required: true
    },
    editable: {
      type: Boolean,
      required: true
    },
  },
  computed: {
    hasMultipleAssignees() {
      return this.numberOfAssignees > 1;
    },
  },
  template: `
    <div class="title hide-collapsed">
      <template v-if="hasMultipleAssignees">
        {{numberOfAssignees}} Assignees
      </template>
      <template v-else>
        Assignee
      </template>
      <i v-if="loading" aria-hidden="true" class="fa fa-spinner fa-spin block-loading"></i>
      <a v-if="editable" class="edit-link pull-right" href="#">Edit</a>
    </div>
  `,
};
