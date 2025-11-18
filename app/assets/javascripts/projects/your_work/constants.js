import emptyStateProjectsSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-projects-md.svg?url';
import { __, s__ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ResourceListsEmptyState, {
  TYPES,
} from '~/vue_shared/components/resource_lists/empty_state.vue';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { PAGINATION_TYPE_KEYSET } from '~/groups_projects/constants';
import { SORT_OPTIONS, SORT_OPTION_UPDATED } from '~/projects/filtered_search_and_sort/constants';
import projectsQuery from './graphql/queries/projects.query.graphql';
import userProjectsQuery from './graphql/queries/user_projects.query.graphql';

const transformSortToUpperCase = (variables) => ({
  ...variables,
  sort: variables.sort.toUpperCase(),
});

const baseTab = {
  paginationType: PAGINATION_TYPE_KEYSET,
  listComponent: ProjectsList,
  listComponentProps: {
    listItemClass: 'gl-px-5',
    showProjectIcon: true,
  },
  emptyStateComponent: ResourceListsEmptyState,
  emptyStateComponentProps: {
    svgPath: emptyStateProjectsSvgPath,
    searchMinimumLength: 3,
    type: TYPES.filter,
  },
  formatter: formatGraphQLProjects,
  queryErrorMessage: __("Your projects couldn't be loaded. Refresh the page to try again."),
  sortOptions: SORT_OPTIONS,
  defaultSortOption: SORT_OPTION_UPDATED,
};

export const CONTRIBUTED_TAB = {
  ...baseTab,
  text: __('Contributed'),
  value: 'contributed',
  query: userProjectsQuery,
  variables: { contributed: true },
  queryPath: 'currentUser.contributedProjects',
  countsQueryPath: 'currentUser.contributed',
  emptyStateComponentProps: {
    ...baseTab.emptyStateComponentProps,
    title: s__("Projects|You haven't contributed to any projects yet."),
    description: s__(
      'Projects|Projects where you contribute code, create issues or epics, or participate in discussions will appear here.',
    ),
  },
  transformVariables: transformSortToUpperCase,
};

export const STARRED_TAB = {
  ...baseTab,
  text: __('Starred'),
  value: 'starred',
  query: userProjectsQuery,
  variables: { starred: true },
  queryPath: 'currentUser.starredProjects',
  countsQueryPath: 'currentUser.starred',
  emptyStateComponentProps: {
    ...baseTab.emptyStateComponentProps,
    title: s__("Projects|You haven't starred any projects yet."),
    description: s__(
      'Projects|Visit a project and select the star icon to save projects you want to find later.',
    ),
  },
  transformVariables: transformSortToUpperCase,
};

export const PERSONAL_TAB = {
  ...baseTab,
  text: __('Personal'),
  value: 'personal',
  query: projectsQuery,
  variables: { personal: true },
  queryPath: 'projects',
  countsQueryPath: 'personal',
  emptyStateComponentProps: {
    ...baseTab.emptyStateComponentProps,
    title: s__("Projects|You don't have any personal projects yet."),
  },
};

export const MEMBER_TAB = {
  ...baseTab,
  text: __('Member'),
  value: 'member',
  query: projectsQuery,
  variables: { membership: true },
  queryPath: 'projects',
  countsQueryPath: 'member',
  emptyStateComponentProps: {
    ...baseTab.emptyStateComponentProps,
    title: s__("Projects|You aren't a member of any projects yet."),
  },
};

export const INACTIVE_TAB = {
  ...baseTab,
  text: __('Inactive'),
  value: 'inactive',
  query: projectsQuery,
  variables: { active: false, membership: true },
  queryPath: 'projects',
  countsQueryPath: 'inactive',
  emptyStateComponentProps: {
    ...baseTab.emptyStateComponentProps,
    title: s__("Projects|You don't have any inactive projects."),
    description: s__('Projects|Projects that are archived or pending deletion will appear here.'),
  },
};

export const PROJECT_DASHBOARD_TABS = [
  CONTRIBUTED_TAB,
  STARRED_TAB,
  PERSONAL_TAB,
  MEMBER_TAB,
  INACTIVE_TAB,
];

export const BASE_ROUTE = '/dashboard/projects';

export const ROOT_ROUTE_NAME = 'root';

export const DASHBOARD_ROUTE_NAME = 'dashboard';

export const PROJECTS_DASHBOARD_ROUTE_NAME = 'projects-dashboard';

export const FIRST_TAB_ROUTE_NAMES = [
  ROOT_ROUTE_NAME,
  DASHBOARD_ROUTE_NAME,
  PROJECTS_DASHBOARD_ROUTE_NAME,
];

export const FILTERED_SEARCH_NAMESPACE = 'dashboard';
export const FILTERED_SEARCH_TERM_KEY = 'name';
