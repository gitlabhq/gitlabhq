export default {
  name: 'NoAssignee',
  props: {
    assignees: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  methods: {
    assignSelf() {
      // const options = {

      // }
      // this.service.save(options);
      this.assignees.addUser();
    }
  },
  template: `
    <div class="value hide-collapsed">
      <span class="assign-yourself no-value">
        No assignee -
        <button type="button" class="btn-link" @click="assignSelf">
          assign yourself
        </button>
      </span>
    </div>
  `,
};
