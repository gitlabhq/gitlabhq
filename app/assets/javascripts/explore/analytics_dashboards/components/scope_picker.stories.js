import createMockApollo from 'helpers/mock_apollo_helper';
import getGroupProjectsQuery from '../graphql/get_group_projects.query.graphql';
import ScopePicker from './scope_picker.vue';

export default {
  component: ScopePicker,
  title: 'explore/analytics_dashboards/components/scope_picker',
};

const groupFullPath = 'gitlab-org';

const mockGroup = {
  __typename: 'Group',
  id: 'gid://gitlab/Group/1',
  name: 'GitLab.org',
  fullName: 'GitLab.org',
  fullPath: groupFullPath,
};

const mockProject = (id, name, path) => ({
  __typename: 'Project',
  id: `gid://gitlab/Project/${id}`,
  name,
  fullName: `GitLab.org / ${name}`,
  fullPath: `${groupFullPath}/${path}`,
});

const respondWith = (projects) => () =>
  Promise.resolve({
    data: {
      group: {
        ...mockGroup,
        projects: { __typename: 'ProjectConnection', nodes: projects },
      },
    },
  });

const Template = (args, { argTypes }) => ({
  components: { ScopePicker },
  apolloProvider: createMockApollo([[getGroupProjectsQuery, args.requestHandler]]),
  props: Object.keys(argTypes),
  template: `
    <div style="height:300px;" class="gl-py-3">
      <scope-picker :group-full-path="groupFullPath" @change="onChange" />
    </div>`,
  methods: {
    onChange(namespace) {
      // eslint-disable-next-line no-console
      console.log('change', namespace);
    },
  },
});

export const Default = Template.bind({});
Default.args = {
  groupFullPath,
  requestHandler: respondWith([
    mockProject(1, 'GitLab', 'gitlab'),
    mockProject(2, 'Charts', 'charts'),
    mockProject(3, 'GitLab Runner', 'gitlab-runner'),
  ]),
};

export const Loading = Template.bind({});
Loading.args = {
  groupFullPath,
  requestHandler: () => new Promise(() => {}),
};
