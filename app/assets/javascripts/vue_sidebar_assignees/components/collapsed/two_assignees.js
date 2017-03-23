export default {
  name: 'CollapsedTwoAssignees',
  props: {
    users: { type: Array, required: true }
  },
  computed: {
    title() {
      return `${this.users[0].name}, ${this.users[1].name}`;
    }
  },
  template: `
    <div class="sidebar-collapsed-icon sidebar-collapsed-user multiple-users"
          data-container="body" data-placement="left"
          data-toggle="tooltip" title="" :data-original-title="title">
      <button class="btn-link" type="button">
        <img width="24" class="avatar avatar-inline s24 " alt="" :src="users[0].avatarUrl">
        <span class="author">{{users[0].name}}</span>
      </button>
      <button class="btn-link" type="button">
        <img width="24" class="avatar avatar-inline s24 " alt="" :src="users[1].avatarUrl">
        <span class="author">{{users[1].name}}</span>
      </button>
    </div>
  `,
};
