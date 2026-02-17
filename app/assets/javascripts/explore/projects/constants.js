import emptyStateProjectsSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-projects-md.svg?url';
import { __, s__ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ResourceListsEmptyState, {
  TYPES,
} from '~/vue_shared/components/resource_lists/empty_state.vue';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { PAGINATION_TYPE_KEYSET } from '~/groups_projects/constants';
import { SORT_OPTION_UPDATED, SORT_OPTIONS } from '~/projects/filtered_search_and_sort/constants';
import projectsQuery from '~/explore/projects/graphql/queries/projects.query.graphql';

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
  queryErrorMessage: __('Projects could not be loaded. Refresh the page to try again.'),
  sortOptions: SORT_OPTIONS,
  defaultSortOption: SORT_OPTION_UPDATED,
  query: projectsQuery,
  queryPath: 'projects',
};

export const ACTIVE_TAB = {
  ...baseTab,
  text: __('Active'),
  value: 'active',
  variables: { active: true },
  emptyStateComponentProps: {
    ...baseTab.emptyStateComponentProps,
    title: s__('Projects|Explore and collaborate on open-source projects'),
    description: s__('Projects|Browse projects to learn from and contribute to.'),
  },
};

export const INACTIVE_TAB = {
  ...baseTab,
  text: __('Inactive'),
  value: 'inactive',
  variables: { active: false },
  emptyStateComponentProps: {
    ...baseTab.emptyStateComponentProps,
    title: s__('Projects|No inactive projects found'),
    description: s__('Projects|View projects that are archived or pending deletion.'),
  },
};

export const TRENDING_TAB = {
  ...baseTab,
  text: __('Trending'),
  value: 'trending',
  variables: { trending: true },
  emptyStateComponentProps: {
    ...baseTab.emptyStateComponentProps,
    title: s__('Projects|No trending projects found'),
    description: s__('Projects|View projects that are trending.'),
  },
};

export const EXPLORE_PROJECTS_TABS = [ACTIVE_TAB, INACTIVE_TAB, TRENDING_TAB];

export const FILTERED_SEARCH_NAMESPACE = 'explore';
export const FILTERED_SEARCH_TERM_KEY = 'name';
