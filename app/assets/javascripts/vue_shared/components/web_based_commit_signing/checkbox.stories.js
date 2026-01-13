import WebBasedCommitSigningCheckbox from './checkbox.vue';

export default {
  component: WebBasedCommitSigningCheckbox,
  title: 'vue_shared/web_based_commit_signing/checkbox',
  argTypes: {
    isChecked: {
      control: 'boolean',
      description: 'Current setting state',
    },
    hasGroupPermissions: {
      control: 'boolean',
      description: 'Whether user has permissions to enable web based commit signing',
    },
    groupSettingsRepositoryPath: {
      control: 'text',
      description: 'Path to the group repository settings page',
    },
    isGroupLevel: {
      control: 'boolean',
      description: 'Whether the setting is inherited from group level',
    },
    disabled: {
      control: 'boolean',
      description: 'Whether checkbox is disabled',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { WebBasedCommitSigningCheckbox },
  props: Object.keys(argTypes),
  template: `
    <web-based-commit-signing-checkbox
      v-bind="$props"
      @update:model-value="value = $event"
    />
  `,
});

export const Default = Template.bind({});
Default.args = {
  isChecked: false,
  hasGroupPermissions: false,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
  isGroupLevel: false,
  disabled: false,
};

export const WithGroupInheritance = Template.bind({});
WithGroupInheritance.args = {
  isChecked: false,
  hasGroupPermissions: false,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
  isGroupLevel: true,
  disabled: false,
};

export const Disabled = Template.bind({});
Disabled.args = {
  isChecked: false,
  hasGroupPermissions: false,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
  disabled: true,
};
