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
import { formatGroups } from './utils';
import groupsQuery from './graphql/queries/groups.query.graphql';
import activeGroupsQuery from './graphql/queries/active_groups.query.graphql';

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
  formatter: formatGroups,
  emptyStateComponent: ResourceListsEmptyState,
  emptyStateComponentProps: {
    svgPath: groupsEmptyStateIllustration,
    title: s__("Organization|You don't have any groups yet."),
    description: s__(
      'Organization|A group is a collection of several projects. If you organize your projects under a group, it works like a folder.',
    ),
    'data-testid': 'groups-empty-state',
  },
  query: groupsQuery,
  queryPath: 'groups',
  paginationType: PAGINATION_TYPE_OFFSET,
  listComponent: NestedGroupsProjectsList,
  queryErrorMessage: __("Your groups couldn't be loaded. Refresh the page to try again."),
  sortOptions: SORT_OPTIONS,
  defaultSortOption: SORT_OPTION_UPDATED,
};

export const MEMBER_TAB = {
  ...baseTab,
  text: __('Member'),
  value: 'member',
  countsQueryPath: 'member',
  query: activeGroupsQuery,
};

export const INACTIVE_TAB = {
  ...baseTab,
  text: __('Inactive'),
  value: 'inactive',
  countsQueryPath: 'inactive',
  variables: { active: false },
  emptyStateComponentProps: {
    svgPath: groupsEmptyStateIllustration,
    title: s__("Groups|You don't have any inactive groups."),
    description: s__('Groups|Groups that are archived or pending deletion will appear here.'),
  },
};

export const GROUP_DASHBOARD_TABS = [MEMBER_TAB, INACTIVE_TAB];

const organizationPath = gon?.current_organization?.full_path || '';
export const BASE_ROUTE = `${organizationPath}/dashboard/groups`;

export const GROUPS_DASHBOARD_ROUTE_NAME = 'groups-dashboard';

export const FIRST_TAB_ROUTE_NAMES = [GROUPS_DASHBOARD_ROUTE_NAME];

export const FILTERED_SEARCH_TERM_KEY = 'filter';
export const FILTERED_SEARCH_NAMESPACE = 'dashboard';
