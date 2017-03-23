import CollapsedAvatar from './avatar';

export default {
  name: 'CollapsedTwoAssignees',
  props: {
    users: { type: Array, required: true },
  },
  computed: {
    title() {
      return `${this.users[0].name}, ${this.users[1].name}`;
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
      <collapsed-avatar :user="users[1]" />
    </div>
  `,
};
