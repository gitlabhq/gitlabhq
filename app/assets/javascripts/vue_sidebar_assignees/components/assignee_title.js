export default {
  name: 'AssigneeTitle',
  props: {
    loading: { type: Boolean, required: true },
    numberOfAssignees: { type: Number, required: true },
    editable: { type: Boolean, required: true },
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
      <i aria-hidden="true" class="fa fa-spinner fa-spin block-loading" :class="{ hidden: !loading }"></i>
      <a class="edit-link pull-right" :class="{ hidden: !editable }" href="#">Edit</a>
    </div>
  `,
};
