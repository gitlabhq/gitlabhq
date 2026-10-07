import createMockApollo from 'helpers/mock_apollo_helper';
// The checkbox label cap that lets long names truncate lives in the page bundle.
import '../../../../stylesheets/page_bundles/explore_analytics_dashboards.scss';
import getSubgroupProjectsQuery from '../graphql/get_subgroup_projects.query.graphql';
import getTopLevelGroupsQuery from '../graphql/get_top_level_groups.query.graphql';
import searchNamespacesGlobalQuery from '../graphql/search_namespaces_global.query.graphql';
import ScopePicker from './scope_picker.vue';

export default {
  component: ScopePicker,
  title: 'explore/analytics_dashboards/components/scope_picker',
};

const groupFullPath = 'gitlab-org';

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

const frontend = mockSubgroup({
  id: 10,
  name: 'Frontend',
  path: 'frontend',
  projectsCount: 1,
  descendantGroupsCount: 2,
});
const mockTopLevelGroup = ({ id, name, path, projectsCount = 0, descendantGroupsCount = 0 }) => ({
  __typename: 'Group',
  id: `gid://gitlab/Group/${id}`,
  name,
  fullName: name,
  fullPath: path,
  projectsCount,
  descendantGroupsCount,
});

const capsuleCorp = mockTopLevelGroup({
  id: 20,
  name: 'Capsule Corp',
  path: 'capsule-corp',
  projectsCount: 2,
  descendantGroupsCount: 1,
});
const acme = mockTopLevelGroup({ id: 21, name: 'Acme Inc', path: 'acme', projectsCount: 1 });
// Nothing beneath it at all, so it gets no chevron.
const empty = mockTopLevelGroup({ id: 22, name: 'Side Quests', path: 'side-quests' });

const topLevelProject = ({ id, name, path, group, parent = group }) => ({
  __typename: 'Project',
  id: `gid://gitlab/Project/${id}`,
  name,
  fullName: `${group.name} / ${name}`,
  fullPath: `${group.fullPath}/${path}`,
  namespace: { __typename: 'Group', id: parent.id, name: parent.name, fullPath: parent.fullPath },
});

// A subgroup of Capsule Corp, which only ever shows up as a project's parent label.
const research = {
  __typename: 'Group',
  id: 'gid://gitlab/Group/23',
  name: 'Research',
  fullPath: `${capsuleCorp.fullPath}/research`,
};

const projectsByTopLevelGroup = {
  [capsuleCorp.fullPath]: [
    topLevelProject({ id: 30, name: 'Time Machine', path: 'time-machine', group: capsuleCorp }),
    topLevelProject({
      id: 31,
      name: 'Gravity Chamber',
      path: 'research/gravity-chamber',
      group: capsuleCorp,
      parent: research,
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

const respondWithSubgroupProjects =
  (projects = projectsByTopLevelGroup) =>
  ({ fullPath }) =>
    Promise.resolve({
      data: {
        group: {
          __typename: 'Group',
          id: `gid://gitlab/Group/${fullPath}`,
          projects: {
            __typename: 'ProjectConnection',
            nodes: projects[fullPath] ?? [],
          },
        },
      },
    });

const Template = (args, { argTypes }) => ({
  components: { ScopePicker },
  apolloProvider: createMockApollo([
    [getSubgroupProjectsQuery, args.subgroupRequestHandler],
    [getTopLevelGroupsQuery, args.topLevelGroupsRequestHandler],
    [searchNamespacesGlobalQuery, args.globalSearchRequestHandler],
  ]),
  props: Object.keys(argTypes),
  template: `
    <div style="height:500px;" class="gl-py-3">
      <scope-picker ref="picker" :require-permissions="requirePermissions" @change="onChange" />
    </div>`,
  mounted() {
    // Expand up front, so stories that are about an expanded top-level group open on that state.
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

// The user's own top-level groups, flat, expanding to every project beneath a group however deep
// it sits -- Gravity Chamber comes from a subgroup, which is what draws its parent label. Side
// Quests holds nothing, so it gets no chevron. One row opens up front, so a single story covers
// both the collapsed and the expanded state.
export const Default = Template.bind({});
Default.args = {
  subgroupRequestHandler: respondWithSubgroupProjects(),
  topLevelGroupsRequestHandler: respondWithTopLevelGroups([capsuleCorp, acme, empty]),
  globalSearchRequestHandler: respondWithGlobalSearch(),
  expandedPath: capsuleCorp.fullPath,
};

// A group can look expandable on its direct counts and still turn up empty -- archived projects
// are counted but excluded, and a subgroup may hold nothing. Acme stands in for that here.
export const EmptyGroup = Template.bind({});
EmptyGroup.args = {
  ...Default.args,
  subgroupRequestHandler: () =>
    Promise.resolve({
      data: {
        group: {
          __typename: 'Group',
          id: acme.id,
          projects: { __typename: 'ProjectConnection', nodes: [] },
        },
      },
    }),
  expandedPath: acme.fullPath,
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

const REQUIRED_PERMISSION = 'readProAiAnalytics';

const restrictGroup = (group) => ({
  ...group,
  userPermissions: { __typename: 'GroupPermissions', [REQUIRED_PERMISSION]: false },
});

const restrictProject = (project) => ({
  ...project,
  userPermissions: { __typename: 'ProjectPermissions', [REQUIRED_PERMISSION]: false },
});

// Rows the user lacks the required permission on carry a Restricted badge and cannot be picked.
// Acme is restricted outright; inside Capsule Corp, Dragon Radar is restricted, and so is Gravity
// Chamber, whose badge takes the place of its parent label.
export const RestrictedNamespaces = Template.bind({});
RestrictedNamespaces.args = {
  ...Default.args,
  requirePermissions: [REQUIRED_PERMISSION],
  topLevelGroupsRequestHandler: respondWithTopLevelGroups([
    capsuleCorp,
    restrictGroup(acme),
    empty,
  ]),
  subgroupRequestHandler: respondWithSubgroupProjects({
    [capsuleCorp.fullPath]: projectsByTopLevelGroup[capsuleCorp.fullPath].map((project) =>
      ['Dragon Radar', 'Gravity Chamber'].includes(project.name)
        ? restrictProject(project)
        : project,
    ),
  }),
};

const longNamesGroup = mockTopLevelGroup({
  id: 50,
  name: 'Scope picker test group with a long name to check truncation',
  path: 'long-names',
  projectsCount: 4,
  descendantGroupsCount: 1,
});

const longNamesSubgroup = {
  __typename: 'Group',
  id: 'gid://gitlab/Group/51',
  name: 'Platform engineering and developer productivity tooling',
  fullPath: `${longNamesGroup.fullPath}/platform`,
};

// Long names truncate with a tooltip, while the parent label and Restricted badge keep up to 3/8 of
// the row. The short name is there to show that names which fit are left alone.
export const LongNames = Template.bind({});
LongNames.args = {
  ...Default.args,
  requirePermissions: [REQUIRED_PERMISSION],
  topLevelGroupsRequestHandler: respondWithTopLevelGroups([longNamesGroup, acme]),
  subgroupRequestHandler: respondWithSubgroupProjects({
    [longNamesGroup.fullPath]: [
      topLevelProject({
        id: 52,
        name: 'Top Project 33 with an exceptionally long name to test truncation in the scope picker xxxxxxxxxxxxxx',
        path: 'top-project-33',
        group: longNamesGroup,
      }),
      topLevelProject({
        id: 53,
        name: 'Nested project with a long name that sits in a subgroup with an equally long name',
        path: 'platform/nested-project',
        group: longNamesGroup,
        parent: longNamesSubgroup,
      }),
      restrictProject(
        topLevelProject({
          id: 54,
          name: 'Restricted project with a long name that must never push its badge out of view',
          path: 'restricted-project',
          group: longNamesGroup,
        }),
      ),
      topLevelProject({ id: 55, name: 'Short name', path: 'short-name', group: longNamesGroup }),
    ],
  }),
  expandedPath: longNamesGroup.fullPath,
};
