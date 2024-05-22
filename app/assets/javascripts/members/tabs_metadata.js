import { __, s__ } from '~/locale';
import PlaceholdersTabApp from './components/placeholders/app.vue';
import { MEMBER_TYPES, TAB_QUERY_PARAM_VALUES } from './constants';

// Overridden in EE
export const TABS = [
  {
    namespace: MEMBER_TYPES.user,
    title: __('Members'),
  },
  {
    namespace: MEMBER_TYPES.group,
    title: __('Groups'),
    attrs: { 'data-testid': 'groups-list-tab' },
    queryParamValue: TAB_QUERY_PARAM_VALUES.group,
  },
  {
    namespace: MEMBER_TYPES.invite,
    title: s__('Members|Pending invitations'),
    requiredPermissions: ['canManageMembers'],
    queryParamValue: TAB_QUERY_PARAM_VALUES.invite,
  },
  {
    namespace: MEMBER_TYPES.accessRequest,
    title: __('Access requests'),
    requiredPermissions: ['canManageAccessRequests'],
    queryParamValue: TAB_QUERY_PARAM_VALUES.accessRequest,
  },
  {
    namespace: MEMBER_TYPES.placeholder,
    title: s__('UserMapping|Placeholders'),
    queryParamValue: TAB_QUERY_PARAM_VALUES.placeholder,
    component: PlaceholdersTabApp,
  },
];
