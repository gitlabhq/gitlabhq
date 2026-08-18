import { __, s__ } from '~/locale';
import PlaceholdersTabApp from './placeholders/components/app.vue';
import { MEMBERS_TAB_TYPES, TAB_QUERY_PARAM_VALUES } from './constants';

// Overridden in EE
export const TABS = [
  {
    namespace: MEMBERS_TAB_TYPES.user,
    title: __('Members'),
  },
  {
    namespace: MEMBERS_TAB_TYPES.directMembers,
    title: __('Direct members'),
    queryParamValue: TAB_QUERY_PARAM_VALUES.directMembers,
    lazy: true,
    // Always show the Direct members tab on the project members page, even when a
    // project has no direct members (all access inherited from the parent group),
    // so the tab is discoverable. The seeded count is accurate (see
    // `direct_members_count`); `alwaysShow` only surfaces the tab when its store
    // module exists, so it does not leak onto the group members page.
    alwaysShow: true,
  },
  {
    namespace: MEMBERS_TAB_TYPES.group,
    title: __('Groups'),
    attrs: { 'data-testid': 'groups-list-tab' },
    queryParamValue: TAB_QUERY_PARAM_VALUES.group,
  },
  {
    namespace: MEMBERS_TAB_TYPES.invite,
    title: s__('Members|Pending invitations'),
    requiredPermissions: ['canManageMembers'],
    queryParamValue: TAB_QUERY_PARAM_VALUES.invite,
  },
  {
    namespace: MEMBERS_TAB_TYPES.accessRequest,
    title: __('Access requests'),
    requiredPermissions: ['canManageAccessRequests'],
    queryParamValue: TAB_QUERY_PARAM_VALUES.accessRequest,
  },
  {
    namespace: MEMBERS_TAB_TYPES.placeholder,
    title: s__('UserMapping|Placeholders'),
    queryParamValue: TAB_QUERY_PARAM_VALUES.placeholder,
    component: PlaceholdersTabApp,
    lazy: true,
  },
];
