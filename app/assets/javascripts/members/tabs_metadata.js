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
