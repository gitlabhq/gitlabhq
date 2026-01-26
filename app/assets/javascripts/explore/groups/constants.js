import groupsEmptyStateIllustration from '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url';
import { s__, __ } from '~/locale';
import {
  SORT_LABEL_NAME,
  SORT_LABEL_CREATED,
  SORT_LABEL_UPDATED,
  PAGINATION_TYPE_OFFSET,
} from '~/groups_projects/constants';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';
import groupsQuery from './graphql/queries/groups.query.graphql';

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

export const SORT_OPTIONS = [SORT_OPTION_NAME, SORT_OPTION_CREATED, SORT_OPTION_UPDATED];

const baseTab = {
  formatter: formatGraphQLGroups,
  emptyStateComponent: ResourceListsEmptyState,
  emptyStateComponentProps: {
    svgPath: groupsEmptyStateIllustration,
    title: s__('Groups|Explore active groups'),
    description: s__('Groups|Browse groups to learn from and contribute to.'),
  },
  query: groupsQuery,
  queryPath: 'groups',
  paginationType: PAGINATION_TYPE_OFFSET,
  listComponent: NestedGroupsProjectsList,
  queryErrorMessage: __("Groups couldn't be loaded. Refresh the page to try again."),
  sortOptions: SORT_OPTIONS,
  defaultSortOption: SORT_OPTION_UPDATED,
};

export const ACTIVE_TAB = {
  ...baseTab,
  text: __('Active'),
  value: 'active',
  countsQueryPath: 'active',
  variables: { active: true },
};

export const INACTIVE_TAB = {
  ...baseTab,
  text: __('Inactive'),
  value: 'inactive',
  countsQueryPath: 'inactive',
  variables: { active: false },
  emptyStateComponentProps: {
    svgPath: groupsEmptyStateIllustration,
    title: s__('Groups|No inactive groups found'),
    description: s__('Groups|Browse groups that are archived or pending deletion.'),
  },
};

export const EXPLORE_GROUPS_TABS = [ACTIVE_TAB, INACTIVE_TAB];
export const EXPLORE_GROUPS_ROUTE_NAME = 'explore-groups';

export const FILTERED_SEARCH_TERM_KEY = 'search';
export const FILTERED_SEARCH_NAMESPACE = 'explore';
