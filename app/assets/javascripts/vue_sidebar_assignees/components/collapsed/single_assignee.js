import CollapsedAvatar from './avatar';

export default {
  name: 'CollapsedSingleAssignee',
  props: {
    users: { type: Array, required: true },
  },
  components: {
    'collapsed-avatar': CollapsedAvatar,
  },
  template: `
    <div class="sidebar-collapsed-icon sidebar-collapsed-user"
        data-container="body"
        data-placement="left"
        data-toggle="tooltip"
        :data-original-title="users[0].name" >
      <collapsed-avatar :user="users[0]" />
    </div>
  `,
};
