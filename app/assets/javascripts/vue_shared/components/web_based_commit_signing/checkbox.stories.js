import WebBasedCommitSigningCheckbox from './checkbox.vue';

export default {
  component: WebBasedCommitSigningCheckbox,
  title: 'vue_shared/web_based_commit_signing/checkbox',
  argTypes: {
    initialValue: {
      control: 'boolean',
      description: 'Initial checkbox state',
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
      description: 'Whether this is a group-level setting',
    },
    groupWebBasedCommitSigningEnabled: {
      control: 'boolean',
      description: 'Whether web based commit signing is enabled at group level (project only)',
    },
    fullPath: {
      control: 'text',
      description: 'Full path of the group or project',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { WebBasedCommitSigningCheckbox },
  props: Object.keys(argTypes),
  template: `
    <web-based-commit-signing-checkbox v-bind="$props" />
  `,
});

export const GroupLevel = Template.bind({});
GroupLevel.args = {
  initialValue: false,
  hasGroupPermissions: true,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
  isGroupLevel: true,
  fullPath: 'my-group',
};

export const GroupLevelChecked = Template.bind({});
GroupLevelChecked.args = {
  initialValue: true,
  hasGroupPermissions: true,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
  isGroupLevel: true,
  fullPath: 'my-group',
};

export const GroupLevelNoPermissions = Template.bind({});
GroupLevelNoPermissions.args = {
  initialValue: false,
  hasGroupPermissions: false,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
  isGroupLevel: true,
  fullPath: 'my-group',
};

export const ProjectLevel = Template.bind({});
ProjectLevel.args = {
  initialValue: false,
  hasGroupPermissions: true,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
  isGroupLevel: false,
  groupWebBasedCommitSigningEnabled: false,
  fullPath: 'my-group/my-project',
};

export const ProjectLevelGroupEnabled = Template.bind({});
ProjectLevelGroupEnabled.args = {
  initialValue: false,
  hasGroupPermissions: true,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
  isGroupLevel: false,
  groupWebBasedCommitSigningEnabled: true,
  fullPath: 'my-group/my-project',
};

export const ProjectLevelNoPermissions = Template.bind({});
ProjectLevelNoPermissions.args = {
  initialValue: false,
  hasGroupPermissions: false,
  groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
  isGroupLevel: false,
  groupWebBasedCommitSigningEnabled: false,
  fullPath: 'my-group/my-project',
};
