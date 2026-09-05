import createMockApollo from 'helpers/mock_apollo_helper';
import getGroupChildrenQuery from '../graphql/get_group_children.query.graphql';
import getSubgroupProjectsQuery from '../graphql/get_subgroup_projects.query.graphql';
import getTopLevelGroupsQuery from '../graphql/get_top_level_groups.query.graphql';
import searchNamespacesQuery from '../graphql/search_namespaces.query.graphql';
import searchNamespacesGlobalQuery from '../graphql/search_namespaces_global.query.graphql';
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

// Rootless mode browses the user's own top-level groups instead of one group's contents.
const mockTopLevelGroup = ({ id, name, path, projectsCount = 0 }) => ({
  __typename: 'Group',
  id: `gid://gitlab/Group/${id}`,
  name,
  fullName: name,
  fullPath: path,
  projectsCount,
});

const capsuleCorp = mockTopLevelGroup({
  id: 20,
  name: 'Capsule Corp',
  path: 'capsule-corp',
  projectsCount: 3,
});
const acme = mockTopLevelGroup({ id: 21, name: 'Acme Inc', path: 'acme', projectsCount: 1 });
// No direct projects, so it gets no chevron.
const empty = mockTopLevelGroup({ id: 22, name: 'Side Quests', path: 'side-quests' });

const topLevelProject = ({ id, name, path, group }) => ({
  __typename: 'Project',
  id: `gid://gitlab/Project/${id}`,
  name,
  fullName: `${group.name} / ${name}`,
  fullPath: `${group.fullPath}/${path}`,
  namespace: { __typename: 'Group', id: group.id, name: group.name, fullPath: group.fullPath },
});

const projectsByTopLevelGroup = {
  [capsuleCorp.fullPath]: [
    topLevelProject({ id: 30, name: 'Time Machine', path: 'time-machine', group: capsuleCorp }),
    topLevelProject({
      id: 31,
      name: 'Gravity Chamber',
      path: 'gravity-chamber',
      group: capsuleCorp,
    }),
    topLevelProject({ id: 32, name: 'Dragon Radar', path: 'dragon-radar', group: capsuleCorp }),
  ],
  [acme.fullPath]: [topLevelProject({ id: 33, name: 'Anvil', path: 'anvil', group: acme })],
};

// Search reaches every depth, so its results come from places the browse view cannot show.
const designSystem = {
  __typename: 'Group',
  id: 'gid://gitlab/Group/40',
  name: 'Design system',
  fullName: 'GitLab.org / Frontend / Design system',
  fullPath: `${groupFullPath}/frontend/design-system`,
  namespace: {
    __typename: 'Group',
    id: frontend.id,
    name: frontend.name,
    fullPath: frontend.fullPath,
  },
};

const searchProjects = [
  {
    ...mockProject(41, 'Pajamas', 'frontend/design-system/pajamas'),
    namespace: {
      __typename: 'Group',
      id: designSystem.id,
      name: designSystem.name,
      fullPath: designSystem.fullPath,
    },
  },
  {
    ...mockProject(42, 'Design tools', 'frontend/tooling/design'),
    namespace: {
      __typename: 'Group',
      id: 'gid://gitlab/Group/13',
      name: 'Tooling',
      fullPath: `${groupFullPath}/frontend/tooling`,
    },
  },
];

const respondWithSearch = () => () =>
  Promise.resolve({
    data: {
      group: {
        ...mockGroup,
        projects: { __typename: 'ProjectConnection', nodes: searchProjects },
        descendantGroups: { __typename: 'GroupConnection', nodes: [designSystem] },
      },
    },
  });

const respondWithGlobalSearch = () => () =>
  Promise.resolve({
    data: {
      groups: { __typename: 'GroupConnection', nodes: [designSystem] },
      projects: { __typename: 'ProjectConnection', nodes: searchProjects },
    },
  });

const respondWithTopLevelGroups = (groups) => () =>
  Promise.resolve({
    data: { groups: { __typename: 'GroupConnection', nodes: groups } },
  });

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

// Serves both modes: a subgroup's whole tree when rooted, a top-level group's own projects
// when not.
const respondWithSubgroupProjects =
  () =>
  ({ fullPath }) =>
    Promise.resolve({
      data: {
        group: {
          __typename: 'Group',
          id: subgroupsByPath[fullPath]?.id ?? `gid://gitlab/Group/${fullPath}`,
          projects: {
            __typename: 'ProjectConnection',
            nodes: projectsBySubgroup[fullPath] ?? projectsByTopLevelGroup[fullPath] ?? [],
          },
        },
      },
    });

const Template = (args, { argTypes }) => ({
  components: { ScopePicker },
  apolloProvider: createMockApollo([
    [getGroupChildrenQuery, args.requestHandler],
    [getSubgroupProjectsQuery, args.subgroupRequestHandler],
    [getTopLevelGroupsQuery, args.topLevelGroupsRequestHandler],
    [searchNamespacesQuery, args.searchRequestHandler],
    [searchNamespacesGlobalQuery, args.globalSearchRequestHandler],
  ]),
  props: Object.keys(argTypes),
  template: `
    <div style="height:500px;" class="gl-py-3">
      <scope-picker ref="picker" :group-full-path="groupFullPath || ''" @change="onChange" />
    </div>`,
  mounted() {
    // Expand up front, so stories that are about an expanded subgroup open on that state.
    if (args.expandedPath) this.$refs.picker.toggleExpanded(args.expandedPath);
    // Same for search: set the term directly, so the results view is what the story opens on.
    // The listbox owns the search input's own value, so the box itself still reads as empty.
    if (args.searchTerm) this.$refs.picker.setSearchTerm(args.searchTerm);
  },
  methods: {
    onChange(namespace) {
      // eslint-disable-next-line no-console
      console.log('change', namespace);
    },
  },
});

// The two browsing modes. Each opens with one row expanded and the rest collapsed, so a single
// story covers both states.

// No group to browse within, which is the component's default and what the instance-level
// Explore page needs. A flat list with no section header, expanding to direct projects only, so
// no parent labels. Side Quests has no direct projects, so it gets no chevron.
export const Default = Template.bind({});
Default.args = {
  groupFullPath: '',
  // Skipped in this mode, but the mock client wants a handler for every query it is given.
  requestHandler: respondWith([]),
  subgroupRequestHandler: respondWithSubgroupProjects(),
  topLevelGroupsRequestHandler: respondWithTopLevelGroups([capsuleCorp, acme, empty]),
  searchRequestHandler: respondWithSearch(),
  globalSearchRequestHandler: respondWithGlobalSearch(),
  expandedPath: capsuleCorp.fullPath,
};

// Given a group, the picker browses inside it instead: two sections, with subgroups of their own.
// Frontend's projects arrive flattened from the subgroups below it, which is what draws the
// parent labels.
export const WithRoot = Template.bind({});
WithRoot.args = {
  ...Default.args,
  groupFullPath,
  requestHandler: respondWith([frontend, quality, incubation]),
  expandedPath: frontend.fullPath,
};

// Shapes only a root can produce. Without one there are no subgroup rows, and chevrons come
// straight from `projectsCount` rather than guessing from direct counts.

// Nothing to put in the second section, so it drops out and only the group's own projects show.
export const NoSubgroups = Template.bind({});
NoSubgroups.args = {
  ...WithRoot.args,
  requestHandler: respondWith([]),
  expandedPath: undefined,
};

// Incubation looks expandable on its direct counts, but nothing turns up beneath it.
export const EmptySubgroup = Template.bind({});
EmptySubgroup.args = {
  ...WithRoot.args,
  requestHandler: respondWith([incubation]),
  expandedPath: incubation.fullPath,
};

// Search replaces the browse view entirely. Results are flat, and every row names its parent,
// since a match can come from any depth. The term is set on mount, so the results view is what
// the story opens on.
export const SearchResults = Template.bind({});
SearchResults.args = {
  ...Default.args,
  searchTerm: 'design',
  expandedPath: undefined,
};
