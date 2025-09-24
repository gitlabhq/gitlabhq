import { __ } from '~/locale';
import {
  SORT_LABEL_NAME,
  SORT_LABEL_CREATED,
  SORT_LABEL_UPDATED,
  SORT_LABEL_STARS,
  PAGINATION_TYPE_OFFSET,
  PAGINATION_TYPE_KEYSET,
} from '~/groups_projects/constants';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { formatGraphQLGroupsAndProjects } from '~/vue_shared/components/nested_groups_projects_list/formatter';
import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import SubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/subgroups_and_projects_empty_state.vue';
import SharedProjectsEmptyState from '~/groups/components/empty_states/shared_projects_empty_state.vue';
import SharedGroupsEmptyState from '~/groups/components/empty_states/shared_groups_empty_state.vue';
import InactiveSubgroupsAndProjectsEmptyState from '~/groups/components/empty_states/inactive_subgroups_and_projects_empty_state.vue';
import sharedGroupsQuery from './graphql/queries/shared_groups.query.graphql';
import subgroupsAndProjectsQuery from './graphql/queries/subgroups_and_projects.query.graphql';
import sharedProjectsQuery from './graphql/queries/shared_projects.query.graphql';

const transformSortToUpperCase = (variables) => ({
  ...variables,
  sort: variables.sort.toUpperCase(),
});

const subgroupsAndProjectsFormatter = (items) =>
  formatGraphQLGroupsAndProjects(
    items,
    (group) => ({
      avatarLabel: group.name,
    }),
    (project) => ({
      avatarLabel: project.name,
    }),
  );

export const SORT_OPTION_NAME = {
  value: 'name',
  text: SORT_LABEL_NAME,
};

export const SORT_OPTION_CREATED = {
  value: 'created_at',
  text: SORT_LABEL_CREATED,
};

export const SORT_OPTION_UPDATED = {
  value: 'updated_at',
  text: SORT_LABEL_UPDATED,
};

export const SORT_OPTION_STARS = {
  value: 'stars',
  text: SORT_LABEL_STARS,
};

export const SORT_OPTIONS = [SORT_OPTION_NAME, SORT_OPTION_CREATED, SORT_OPTION_UPDATED];
export const SORT_OPTIONS_WITH_STARS = [...SORT_OPTIONS, SORT_OPTION_STARS];

const baseSubgroupsAndProjectsTab = {
  query: subgroupsAndProjectsQuery,
  queryPath: 'subgroupsAndProjects',
  paginationType: PAGINATION_TYPE_OFFSET,
  formatter: subgroupsAndProjectsFormatter,
  listComponent: NestedGroupsProjectsList,
  listComponentProps: {
    includeMicrodata: true,
  },
  queryErrorMessage: __(
    "Your subgroups and projects couldn't be loaded. Refresh the page to try again.",
  ),
  sortOptions: SORT_OPTIONS_WITH_STARS,
  defaultSortOption: SORT_OPTION_UPDATED,
};

export const SUBGROUPS_AND_PROJECTS_TAB = {
  ...baseSubgroupsAndProjectsTab,
  variables: { active: true },
  text: __('Subgroups and projects'),
  value: 'subgroups_and_projects',
  emptyStateComponent: SubgroupsAndProjectsEmptyState,
};

export const SHARED_PROJECTS_TAB = {
  query: sharedProjectsQuery,
  queryPath: 'group.sharedProjects',
  paginationType: PAGINATION_TYPE_KEYSET,
  formatter: formatGraphQLProjects,
  listComponent: ProjectsList,
  listComponentProps: {
    listItemClass: 'gl-px-5',
    showProjectIcon: true,
  },
  emptyStateComponent: SharedProjectsEmptyState,
  text: __('Shared projects'),
  value: 'shared_projects',
  transformVariables: transformSortToUpperCase,
  queryErrorMessage: __('Shared projects could not be loaded. Refresh the page to try again.'),
  sortOptions: SORT_OPTIONS,
  defaultSortOption: SORT_OPTION_UPDATED,
};

export const SHARED_GROUPS_TAB = {
  query: sharedGroupsQuery,
  queryPath: 'group.sharedGroups',
  paginationType: PAGINATION_TYPE_KEYSET,
  formatter: formatGraphQLGroups,
  listComponent: GroupsList,
  listComponentProps: {
    listItemClass: 'gl-px-5',
    showGroupIcon: true,
  },
  emptyStateComponent: SharedGroupsEmptyState,
  text: __('Shared groups'),
  value: 'shared_groups',
  transformVariables: transformSortToUpperCase,
  sortOptions: SORT_OPTIONS,
  defaultSortOption: SORT_OPTION_UPDATED,
};

export const INACTIVE_TAB = {
  ...baseSubgroupsAndProjectsTab,
  variables: { active: false },
  text: __('Inactive'),
  value: 'inactive',
  emptyStateComponent: InactiveSubgroupsAndProjectsEmptyState,
};

export const GROUPS_SHOW_TABS = [
  SUBGROUPS_AND_PROJECTS_TAB,
  SHARED_PROJECTS_TAB,
  SHARED_GROUPS_TAB,
  INACTIVE_TAB,
];

export const BASE_ROUTE = '/(groups)?/:group*';

export const FILTERED_SEARCH_TERM_KEY = 'filter';
export const FILTERED_SEARCH_NAMESPACE = 'groups-show';
