export default {
  name: 'NoAssignee',
  props: {
    assignees: {
      type: Object,
      required: true
    },
  },
  methods: {
    assignSelf() {
      this.assignees.addCurrentUser();
    },
  },
  template: `
    <div class="hide-collapsed">
      <span class="assign-yourself no-value">
        No assignee -
        <button type="button" class="btn-link" @click="assignSelf">
          assign yourself
        </button>
      </span>
    </div>
  `,
};
