// Temporary Storybook file for local review — can be removed after migration is complete.
import MirrorTable from './mirror_table.vue';

export default {
  title: 'mirrors/mirror_table',
  component: MirrorTable,
};

const defaultProvide = {
  projectId: 7,
  settingsEnabled: true,
  repositoryMirrorsAvailable: false,
};

const createMirrorData = (overrides = {}) => ({
  id: 42,
  enabled: true,
  url: 'https://example.com/mirror.git',
  direction: 'push',
  lastUpdateStartedAt: '2024-01-01T00:00:00Z',
  lastUpdateAt: '2024-01-01T00:00:00Z',
  lastError: null,
  updateStatus: 'finished',
  sshKeyAuth: false,
  sshPublicKey: null,
  disabled: false,
  ...overrides,
});

const Template = (args, { argTypes }) => ({
  components: { MirrorTable },
  props: Object.keys(argTypes),
  provide: defaultProvide,
  template: '<mirror-table v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  initialMirrors: [
    createMirrorData({ id: 1 }),
    createMirrorData({ id: 2, url: 'https://example.com/mirror2.git' }),
  ],
};

const EmptyTemplate = (args, { argTypes }) => ({
  components: { MirrorTable },
  props: Object.keys(argTypes),
  provide: defaultProvide,
  template: '<mirror-table v-bind="$props" />',
});

export const Empty = EmptyTemplate.bind({});
Empty.args = {
  initialMirrors: [],
};

const WithSSHKeyTemplate = (args, { argTypes }) => ({
  components: { MirrorTable },
  props: Object.keys(argTypes),
  provide: defaultProvide,
  template: '<mirror-table v-bind="$props" />',
});

export const WithSSHKey = WithSSHKeyTemplate.bind({});
WithSSHKey.args = {
  initialMirrors: [createMirrorData({ id: 1, sshKeyAuth: true, sshPublicKey: 'ssh-rsa AAAA...' })],
};

const WithErrorTemplate = (args, { argTypes }) => ({
  components: { MirrorTable },
  props: Object.keys(argTypes),
  provide: defaultProvide,
  template: '<mirror-table v-bind="$props" />',
});

export const WithError = WithErrorTemplate.bind({});
WithError.args = {
  initialMirrors: [createMirrorData({ id: 1, lastError: 'Connection refused' })],
};

const DisabledMirrorTemplate = (args, { argTypes }) => ({
  components: { MirrorTable },
  props: Object.keys(argTypes),
  provide: defaultProvide,
  template: '<mirror-table v-bind="$props" />',
});

export const DisabledMirror = DisabledMirrorTemplate.bind({});
DisabledMirror.args = {
  initialMirrors: [createMirrorData({ id: 1, enabled: false, disabled: true })],
};

const WithBranchSettingsTemplate = (args, { argTypes }) => ({
  components: { MirrorTable },
  props: Object.keys(argTypes),
  provide: {
    ...defaultProvide,
    repositoryMirrorsAvailable: true,
  },
  template: '<mirror-table v-bind="$props" />',
});

export const WithBranchSettings = WithBranchSettingsTemplate.bind({});
WithBranchSettings.args = {
  initialMirrors: [createMirrorData({ id: 1, mirrorBranchesSetting: 'protected' })],
};

const UpdatingTemplate = (args, { argTypes }) => ({
  components: { MirrorTable },
  props: Object.keys(argTypes),
  provide: defaultProvide,
  template: '<mirror-table v-bind="$props" />',
});

export const Updating = UpdatingTemplate.bind({});
Updating.args = {
  initialMirrors: [createMirrorData({ id: 1, updateStatus: 'started' })],
};
