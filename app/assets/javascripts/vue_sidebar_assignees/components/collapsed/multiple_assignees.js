export default {
  name: 'CollapsedMultipleAssignees',
  props: {
    users: { type: Array, required: true }
  },
  computed: {
    title() {
      const max = this.users.length > 5 ? 5 : this.users.length;
      const firstFive = this.users.slice(0, max);
      const names = [];

      firstFive.forEach((u) => names.push(u.name));

      if (this.users.length > max) {
        names.push(`+${this.users.length - max} more`);
      }

      return names.join(', ');
    },
    counter() {
      if (this.users.length > 99) {
        return '99+';
      } else {
        return `+${this.users.length - 1}`;
      }
    },
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
        <span class="avatar-counter sidebar-avatar-counter">{{counter}}</span>
      </button>
    </div>
  `,
};
