import CollapsedAvatar from './avatar';

export default {
  name: 'CollapsedMultipleAssignees',
  props: {
    users: { type: Array, required: true },
  },
  computed: {
    title() {
      const maxRender = Math.min(5, this.users.length);
      const renderUsers = this.users.slice(0, maxRender);
      const names = [];

      renderUsers.forEach(u => names.push(u.name));

      if (this.users.length > maxRender) {
        names.push(`+${this.users.length - maxRender} more`);
      }

      return names.join(', ');
    },
    counter() {
      let counter = `+${this.users.length - 1}`;

      if (this.users.length > 99) {
        counter = '99+';
      }

      return counter;
    },
  },
  components: {
    'collapsed-avatar': CollapsedAvatar,
  },
  template: `
    <div class="sidebar-collapsed-icon sidebar-collapsed-user multiple-users"
        data-container="body"
        data-placement="left"
        data-toggle="tooltip"
        :data-original-title="title" >
      <collapsed-avatar :user="users[0]" />
      <button class="btn-link" type="button">
        <span class="avatar-counter sidebar-avatar-counter">{{counter}}</span>
      </button>
    </div>
  `,
};
