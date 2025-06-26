import { __ } from '~/locale';
import {
  SORT_LABEL_NAME,
  SORT_LABEL_CREATED,
  SORT_LABEL_UPDATED,
  SORT_LABEL_STORAGE_SIZE,
} from '~/groups_projects/constants';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';
import adminGroupsQuery from './graphql/queries/groups.query.graphql';

const baseTab = {
  formatter: (groups) =>
    formatGraphQLGroups(groups, (group) => {
      const adminPath = `/admin/groups/${group.fullPath}`;

      return {
        avatarLabelLink: adminPath,
        editPath: `${adminPath}/edit`,
      };
    }),
  listComponent: GroupsList,
  listComponentProps: {
    listItemClass: 'gl-px-5',
    showGroupIcon: true,
  },
  query: adminGroupsQuery,
  queryPath: 'groups',
};

export const ACTIVE_TAB = {
  ...baseTab,
  text: __('Active'),
  value: 'active',
  variables: { active: true },
  countsQueryPath: 'active',
};

export const INACTIVE_TAB = {
  ...baseTab,
  text: __('Inactive'),
  value: 'inactive',
  variables: { active: false },
  countsQueryPath: 'inactive',
};

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

export const SORT_OPTION_STORAGE_SIZE = {
  value: 'storage_size',
  text: SORT_LABEL_STORAGE_SIZE,
};

export const SORT_OPTIONS = [
  SORT_OPTION_NAME,
  SORT_OPTION_CREATED,
  SORT_OPTION_UPDATED,
  SORT_OPTION_STORAGE_SIZE,
];

export const ADMIN_GROUPS_TABS = [ACTIVE_TAB, INACTIVE_TAB];

export const BASE_ROUTE = '/admin/groups';

export const ADMIN_GROUPS_ROUTE_NAME = 'admin-groups';

export const FIRST_TAB_ROUTE_NAMES = [ADMIN_GROUPS_ROUTE_NAME];

export const FILTERED_SEARCH_TERM_KEY = 'search';
export const FILTERED_SEARCH_NAMESPACE = 'admin-groups';
