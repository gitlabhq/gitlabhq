import createMockApollo from 'helpers/mock_apollo_helper';
import getGroupChildrenQuery from '../graphql/get_group_children.query.graphql';
import getSubgroupProjectsQuery from '../graphql/get_subgroup_projects.query.graphql';
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

const mockSubgroup = ({ id, name, path, projectsCount = 0, descendantGroupsCount = 0 }) => ({
  __typename: 'Group',
  id: `gid://gitlab/Group/${id}`,
  name,
  fullName: `GitLab.org / ${name}`,
  fullPath: `${groupFullPath}/${path}`,
  projectsCount,
  descendantGroupsCount,
});

const mockNamespace = (id, name, path) => ({
  __typename: 'Group',
  id: `gid://gitlab/Group/${id}`,
  name,
  fullPath: `${groupFullPath}/${path}`,
});

const frontend = mockSubgroup({
  id: 10,
  name: 'Frontend',
  path: 'frontend',
  projectsCount: 1,
  descendantGroupsCount: 2,
});
const quality = mockSubgroup({ id: 11, name: 'Quality', path: 'quality', projectsCount: 2 });
// Its direct counts say it holds a subgroup, but nothing turns up beneath it once expanded.
const incubation = mockSubgroup({
  id: 12,
  name: 'Incubation',
  path: 'incubation',
  descendantGroupsCount: 1,
});

const projects = [
  mockProject(1, 'GitLab', 'gitlab'),
  mockProject(2, 'Charts', 'charts'),
  mockProject(3, 'GitLab Runner', 'gitlab-runner'),
];

// Keyed by subgroup, so expanding Quality does not render Frontend's projects. Frontend's set
// mixes a direct project with two from subgroups below it, which is what draws the parent labels.
const projectsBySubgroup = {
  [frontend.fullPath]: [
    {
      ...mockProject(4, 'GitLab UI', 'frontend/gitlab-ui'),
      namespace: mockNamespace(10, 'Frontend', 'frontend'),
    },
    {
      ...mockProject(5, 'Design tools', 'frontend/tooling/design'),
      namespace: mockNamespace(13, 'Tooling', 'frontend/tooling'),
    },
    {
      ...mockProject(6, 'Pajamas', 'frontend/design-system/pajamas'),
      namespace: mockNamespace(14, 'Design system', 'frontend/design-system'),
    },
  ],
  [quality.fullPath]: [
    {
      ...mockProject(7, 'Test tooling', 'quality/test-tooling'),
      namespace: mockNamespace(11, 'Quality', 'quality'),
    },
    {
      ...mockProject(8, 'Triage ops', 'quality/triage/triage-ops'),
      namespace: mockNamespace(15, 'Triage', 'quality/triage'),
    },
  ],
  [incubation.fullPath]: [],
};

const respondWith = (subgroups) => () =>
  Promise.resolve({
    data: {
      group: {
        ...mockGroup,
        projects: { __typename: 'ProjectConnection', nodes: projects },
        descendantGroups: { __typename: 'GroupConnection', nodes: subgroups },
      },
    },
  });

const subgroupsByPath = Object.fromEntries(
  [frontend, quality, incubation].map((subgroup) => [subgroup.fullPath, subgroup]),
);

const respondWithSubgroupProjects =
  () =>
  ({ fullPath }) =>
    Promise.resolve({
      data: {
        group: {
          __typename: 'Group',
          id: subgroupsByPath[fullPath].id,
          projects: {
            __typename: 'ProjectConnection',
            nodes: projectsBySubgroup[fullPath] ?? [],
          },
        },
      },
    });

const Template = (args, { argTypes }) => ({
  components: { ScopePicker },
  apolloProvider: createMockApollo([
    [getGroupChildrenQuery, args.requestHandler],
    [getSubgroupProjectsQuery, args.subgroupRequestHandler],
  ]),
  props: Object.keys(argTypes),
  template: `
    <div style="height:500px;" class="gl-py-3">
      <scope-picker ref="picker" :group-full-path="groupFullPath" @change="onChange" />
    </div>`,
  mounted() {
    // Expand up front, so stories that are about an expanded subgroup open on that state.
    if (args.expandedPath) this.$refs.picker.toggleExpanded(args.expandedPath);
  },
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
  requestHandler: respondWith([frontend, quality, incubation]),
  subgroupRequestHandler: respondWithSubgroupProjects(),
};

export const SubgroupExpanded = Template.bind({});
SubgroupExpanded.args = {
  ...Default.args,
  expandedPath: frontend.fullPath,
};

export const NoSubgroups = Template.bind({});
NoSubgroups.args = {
  groupFullPath,
  requestHandler: respondWith([]),
  subgroupRequestHandler: respondWithSubgroupProjects(),
};

// Incubation looks expandable on its direct counts, but nothing turns up beneath it.
export const EmptySubgroup = Template.bind({});
EmptySubgroup.args = {
  groupFullPath,
  requestHandler: respondWith([incubation]),
  subgroupRequestHandler: respondWithSubgroupProjects(),
  expandedPath: incubation.fullPath,
};

export const SubgroupLoading = Template.bind({});
SubgroupLoading.args = {
  groupFullPath,
  requestHandler: respondWith([frontend, quality]),
  subgroupRequestHandler: () => new Promise(() => {}),
  expandedPath: frontend.fullPath,
};

export const Loading = Template.bind({});
Loading.args = {
  groupFullPath,
  requestHandler: () => new Promise(() => {}),
  subgroupRequestHandler: respondWithSubgroupProjects(),
};
