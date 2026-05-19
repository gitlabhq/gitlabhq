import createMockApollo from 'helpers/mock_apollo_helper';
import getProjects from '../graphql/projects.query.graphql';
import ProjectsDropdownFilter from './projects_dropdown_filter.vue';

export default {
  component: ProjectsDropdownFilter,
  title: 'analytics/shared/components/projects_dropdown_filter',
};

const id = 'gid://gitlab/Group/fake-id';
const nodes = [
  {
    id: 'gid://gitlab/Project/1',
    name: 'GitLab',
    fullPath: 'gitlab-org/gitlab',
    avatarUrl: `/assets/images/logo.svg`,
  },
  {
    id: 'gid://gitlab/Project/2',
    name: 'GitLab Runner',
    fullPath: 'gitlab-org/gitlab-runner',
    avatarUrl: null,
  },
  {
    id: 'gid://gitlab/Project/3',
    name: 'Foo Project',
    fullPath: 'gitlab-org/foo-project',
    avatarUrl: null,
  },
];

const mockApolloProvider = () =>
  createMockApollo([[getProjects, () => ({ data: { group: { id, projects: { nodes } } } })]]);

const Template = (args, { argTypes }) => ({
  components: { ProjectsDropdownFilter },
  apolloProvider: mockApolloProvider(),
  props: Object.keys(argTypes),
  template: `
    <div style="height:200px;" class="gl-py-3">
      <projects-dropdown-filter v-bind="$props" />
    </div>`,
});

export const Default = Template.bind({});
Default.args = {
  groupNamespace: 'gitlab-fake',
};

export const LoadingDefaultProjects = Template.bind({});
LoadingDefaultProjects.args = {
  groupNamespace: 'gitlab-fake',
  loadingDefaultProjects: true,
};

export const WithDefaultProjects = Template.bind({});
WithDefaultProjects.args = {
  groupNamespace: 'gitlab-fake',
  defaultProjects: [nodes[0]],
};

export const MultiSelect = Template.bind({});
MultiSelect.args = {
  groupNamespace: 'gitlab-fake',
  multiSelect: true,
};
