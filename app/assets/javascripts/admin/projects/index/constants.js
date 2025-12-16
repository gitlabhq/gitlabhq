import { get } from 'lodash';
import emptyStateProjectsSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-projects-md.svg?url';
import { __, s__ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ResourceListsEmptyState, {
  TYPES,
} from '~/vue_shared/components/resource_lists/empty_state.vue';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import {
  SORT_LABEL_CREATED,
  SORT_LABEL_NAME,
  SORT_LABEL_STARS,
  SORT_LABEL_STORAGE_SIZE,
  SORT_LABEL_UPDATED,
  PAGINATION_TYPE_KEYSET,
} from '~/groups_projects/constants';
import projectsQuery from './graphql/queries/admin_projects.query.graphql';

export const SORT_OPTION_NAME = {
  value: 'name',
  text: SORT_LABEL_NAME,
};

export const SORT_OPTION_CREATED = {
  value: 'created',
  text: SORT_LABEL_CREATED,
};

export const SORT_OPTION_UPDATED = {
  value: 'latest_activity',
  text: SORT_LABEL_UPDATED,
};

export const SORT_OPTION_STARS = {
  value: 'stars',
  text: SORT_LABEL_STARS,
};

export const SORT_OPTION_STORAGE_SIZE = {
  value: 'storage_size',
  text: SORT_LABEL_STORAGE_SIZE,
};

export const SORT_OPTIONS = [
  SORT_OPTION_NAME,
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
  SORT_OPTION_STARS,
  SORT_OPTION_STORAGE_SIZE,
];

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
  paginationType: PAGINATION_TYPE_KEYSET,
  formatter: (projects) =>
    formatGraphQLProjects(projects, (project) => {
      const canAdminAllResources = get(project.userPermissions, 'adminAllResources', true);

      return {
        editPath: project.adminEditPath,
        avatarLabelLink: project.adminShowPath,
        availableActions: canAdminAllResources ? project.availableActions : [],
      };
    }),
  sortOptions: SORT_OPTIONS,
  defaultSortOption: SORT_OPTION_UPDATED,
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

export const BASE_ROUTE = '/';

export const ADMIN_PROJECTS_ROUTE_NAME = 'admin-projects';
export const FIRST_TAB_ROUTE_NAMES = [ADMIN_PROJECTS_ROUTE_NAME];

export const FILTERED_SEARCH_NAMESPACE = 'admin-projects';
export const FILTERED_SEARCH_TERM_KEY = 'search';
