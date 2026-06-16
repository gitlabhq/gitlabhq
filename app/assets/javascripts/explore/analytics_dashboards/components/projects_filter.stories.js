import createMockApollo from 'helpers/mock_apollo_helper';
import getProjects from '~/analytics/shared/graphql/projects.query.graphql';
import ProjectsFilter from './projects_filter.vue';

export default {
  component: ProjectsFilter,
  title: 'explore/analytics_dashboards/components/projects_filter',
};

const id = 1;
const groupNamespace = 'fake-groups';

const nodes = [
  {
    id: 'gid://gitlab/Project/1',
    name: 'Gitlab Test',
    fullPath: 'gitlab-org/gitlab-test',
    avatarUrl: `/assets/images/logo.svg`,
  },
  {
    id: 'gid://gitlab/Project/2',
    name: 'Gitlab Shell',
    fullPath: 'gitlab-org/gitlab-shell',
    avatarUrl: null,
  },
  {
    id: 'gid://gitlab/Project/3',
    name: 'Foo',
    fullPath: 'gitlab-org/foo',
    avatarUrl: null,
  },
];

const mockApolloProvider = () =>
  createMockApollo([[getProjects, () => ({ data: { group: { id, projects: { nodes } } } })]]);

const Template = (args, { argTypes }) => ({
  components: { ProjectsFilter },
  apolloProvider: mockApolloProvider(),
  props: Object.keys(argTypes),
  template: `
    <div style="height:200px;" class="gl-py-3">
      <projects-filter v-bind="$props" />
    </div>`,
});

export const Default = Template.bind({});
Default.args = {
  groupNamespace,
};

export const MultiSelect = Template.bind({});
MultiSelect.args = {
  groupNamespace,
  multiSelect: true,
};
