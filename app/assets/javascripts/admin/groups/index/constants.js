import { get } from 'lodash';
import groupsEmptyStateIllustration from '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url';
import { s__, __ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import {
  SORT_LABEL_NAME,
  SORT_LABEL_CREATED,
  SORT_LABEL_UPDATED,
  SORT_LABEL_STORAGE_SIZE,
  PAGINATION_TYPE_KEYSET,
} from '~/groups_projects/constants';
import GroupsList from '~/vue_shared/components/groups_list/groups_list.vue';
import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import adminGroupsQuery from './graphql/queries/groups.query.graphql';

const baseTab = {
  formatter: (groups) =>
    formatGraphQLGroups(groups, (group) => {
      const adminPath = joinPaths('/', gon.relative_url_root, '/admin/groups/', group.fullPath);
      const canAdminAllResources = get(group.userPermissions, 'adminAllResources', true);

      return {
        avatarLabelLink: adminPath,
        editPath: `${adminPath}/edit`,
        availableActions: canAdminAllResources ? group.availableActions : [],
      };
    }),
  listComponent: GroupsList,
  listComponentProps: {
    listItemClass: 'gl-px-5',
    showGroupIcon: true,
  },
  emptyStateComponent: ResourceListsEmptyState,
  query: adminGroupsQuery,
  queryPath: 'groups',
  paginationType: PAGINATION_TYPE_KEYSET,
};

export const ACTIVE_TAB = {
  ...baseTab,
  text: __('Active'),
  value: 'active',
  variables: { active: true },
  countsQueryPath: 'active',
  emptyStateComponentProps: {
    svgPath: groupsEmptyStateIllustration,
    title: s__("Groups|You don't have any active groups yet."),
    description: s__(
      'Organization|A group is a collection of several projects. If you organize your projects under a group, it works like a folder.',
    ),
    'data-testid': 'groups-empty-state',
  },
};

export const INACTIVE_TAB = {
  ...baseTab,
  text: __('Inactive'),
  value: 'inactive',
  variables: { active: false },
  countsQueryPath: 'inactive',
  emptyStateComponentProps: {
    svgPath: groupsEmptyStateIllustration,
    title: s__("Groups|You don't have any inactive groups."),
    description: s__('Groups|Groups that are archived or pending deletion will appear here.'),
  },
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
