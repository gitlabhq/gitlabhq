export default {
  name: 'NoAssignee',
  props: {
    assignees: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  methods: {
    assignSelf() {
      this.service.add(this.assignees.currentUser.id).then((response) => {
        const data = response.data;
        const assignee = data.assignee;
        this.assignees.addUser(assignee.name, assignee.username, assignee.avatar_url);
      }).catch((err) => {
        console.log(err);
        console.log('error');
      });
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
