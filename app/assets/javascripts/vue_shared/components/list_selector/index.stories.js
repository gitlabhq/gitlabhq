import {
  USERS_RESPONSE_MOCK,
  GROUPS_RESPONSE_MOCK,
} from 'jest/vue_shared/components/list_selector/mock_data';
import ListSelector from './index.vue';

export default {
  component: ListSelector,
  title: 'vue_shared/list_selector',
};

const Template = (args, { argTypes }) => ({
  components: { ListSelector },
  props: Object.keys(argTypes),
  template: '<list-selector v-bind="$props" />',
});

const defaultArgs = {
  projectPath: '/project/path',
  groupPath: '/group/path',
  disableNamespaceDropdown: false,
};

export const UsersType = Template.bind({});
UsersType.args = {
  ...defaultArgs,
  type: 'users',
  selectedItems: USERS_RESPONSE_MOCK,
};

export const GroupsType = Template.bind({});
GroupsType.args = {
  ...defaultArgs,
  type: 'groups',
  selectedItems: GROUPS_RESPONSE_MOCK.data.groups.nodes,
};

export const GroupsWithDisabledDropdownType = Template.bind({});
GroupsWithDisabledDropdownType.args = {
  ...defaultArgs,
  type: 'groups',
  disableNamespaceDropdown: true,
  selectedItems: GROUPS_RESPONSE_MOCK.data.groups.nodes,
};

export const ProjectsType = Template.bind({});
ProjectsType.args = {
  ...defaultArgs,
  type: 'projects',
  selectedItems: [
    {
      id: 1,
      name: 'Project 1',
      nameWithNamespace: 'project1',
      avatarUrl:
        'https://www.gravatar.com/avatar/c4ab964b90c3049c47882b319d3c5cc0?s=80\u0026d=identicon',
    },
  ],
};

export const DeployKeysType = Template.bind({});
DeployKeysType.args = {
  ...defaultArgs,
  type: 'deployKeys',
  selectedItems: [
    {
      id: 1,
      title: 'Deploy key 1',
      user: {
        name: 'Jane Smith',
      },
    },
  ],
};
