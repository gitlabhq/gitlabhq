import GroupInheritancePopover from './group_inheritance_popover.vue';

export default {
  component: GroupInheritancePopover,
  title: 'vue_shared/settings/group_inheritance_popover',
  argTypes: {
    hasGroupPermissions: {
      control: 'boolean',
      description: 'Whether the user has group permissions to edit settings',
    },
    groupSettingsRepositoryPath: {
      control: 'text',
      description: 'Path to the group repository settings page',
    },
  },
};

const Template = (args) => ({
  components: { GroupInheritancePopover },
  setup() {
    return { args };
  },
  template: `
    <div class="gl-p-4">
      <p class="gl-mb-4">Hover over or focus the lock icon to see the popover:</p>
      <group-inheritance-popover v-bind="args" />
    </div>
  `,
});

export const Default = Template.bind({});
Default.args = {
  hasGroupPermissions: false,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
};

export const WithGroupPermissions = Template.bind({});
WithGroupPermissions.args = {
  hasGroupPermissions: true,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
};
