export default {
  name: 'CollapsedNoAssignee',
  props: {
    users: { type: Array, required: true },
  },
  template: `
    <div class="sidebar-collapsed-icon sidebar-collapsed-user">
      <i aria-hidden="true" class="fa fa-user"></i>
    </div>
  `,
};
