import emptyStateProjectsSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-projects-md.svg?url';
import { __, s__ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ResourceListsEmptyState, {
  TYPES,
} from '~/vue_shared/components/resource_lists/empty_state.vue';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import projectsQuery from './graphql/queries/projects.query.graphql';

const baseTab = {
  listComponent: ProjectsList,
  listComponentProps: {
    listItemClass: 'gl-px-5',
    showProjectIcon: true,
  },
  emptyStateComponent: ResourceListsEmptyState,
  emptyStateComponentProps: {
    title: s__('Projects|No projects found.'),
    svgPath: emptyStateProjectsSvgPath,
    searchMinimumLength: 3,
    type: TYPES.filter,
  },
  queryPath: 'projects',
  formatter: (projects) =>
    formatGraphQLProjects(projects, (project) => ({
      editPath: `/admin/projects/${project.fullPath}/edit`,
      avatarLabelLink: `/admin/projects/${project.fullPath}`,
    })),
};

export const ACTIVE_TAB = {
  ...baseTab,
  text: __('Active'),
  value: 'active',
  query: projectsQuery,
  variables: { active: true },
  queryPath: 'projects',
  countsQueryPath: 'active',
};

export const INACTIVE_TAB = {
  ...baseTab,
  text: __('Inactive'),
  value: 'inactive',
  query: projectsQuery,
  variables: { active: false },
  queryPath: 'projects',
  countsQueryPath: 'inactive',
  emptyStateComponentProps: {
    ...baseTab.emptyStateComponentProps,
    title: s__("Projects|You don't have any inactive projects."),
    description: s__('Projects|Projects that are archived or pending deletion will appear here.'),
  },
};

export const ADMIN_PROJECTS_TABS = [ACTIVE_TAB, INACTIVE_TAB];

export const BASE_ROUTE = '/admin/projects';

export const ADMIN_PROJECTS_ROUTE_NAME = 'admin-projects';
export const FIRST_TAB_ROUTE_NAMES = [ADMIN_PROJECTS_ROUTE_NAME];

export const FILTERED_SEARCH_NAMESPACE = 'admin';
export const FILTERED_SEARCH_TERM_KEY = 'search';
