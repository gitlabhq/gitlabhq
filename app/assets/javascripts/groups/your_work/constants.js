import { __ } from '~/locale';
import {
  SORT_LABEL_NAME,
  SORT_LABEL_CREATED,
  SORT_LABEL_UPDATED,
} from '~/groups_projects/constants';
import NestedGroupsProjectsList from '~/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list.vue';
import { formatGroups } from '~/organizations/shared/utils';
import memberGroupsQuery from './graphql/queries/member_groups.query.graphql';

const baseTab = {
  formatter: formatGroups,
};

export const MEMBER_TAB = {
  ...baseTab,
  text: __('Member'),
  value: 'member',
  query: memberGroupsQuery,
  queryPath: 'groups',
  listComponent: NestedGroupsProjectsList,
};

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

export const SORT_OPTIONS = [SORT_OPTION_NAME, SORT_OPTION_CREATED, SORT_OPTION_UPDATED];

export const GROUP_DASHBOARD_TABS = [MEMBER_TAB];

export const BASE_ROUTE = '/dashboard/groups';

export const GROUPS_DASHBOARD_ROUTE_NAME = 'groups-dashboard';

export const FILTERED_SEARCH_TERM_KEY = 'filter';
export const FILTERED_SEARCH_NAMESPACE = 'dashboard';
