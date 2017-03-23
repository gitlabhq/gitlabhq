export default {
  name: 'CollapsedSingleAssignee',
  props: {
    users: { type: Array, required: true }
  },
  template: `
    <div class="sidebar-collapsed-icon sidebar-collapsed-user"
          data-container="body" data-placement="left"
          data-toggle="tooltip" title="" :data-original-title="users[0].name">
      <button class="btn-link" type="button">
        <img width="24" class="avatar avatar-inline s24 " alt="" :src="users[0].avatarUrl">
        <span class="author">{{users[0].name}}</span>
      </button>
    </div>
  `,
};
