import { __, s__ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import {
  STATUS_ACTIVE,
  STATUS_PAUSED,
  STATUS_ONLINE,
  STATUS_OFFLINE,
  STATUS_NOT_CONNECTED,
  PARAM_KEY_STATUS,
} from '../../constants';

export const statusTokenConfig = {
  icon: 'status',
  title: __('Status'),
  type: PARAM_KEY_STATUS,
  token: BaseToken,
  unique: true,
  options: [
    { value: STATUS_ACTIVE, title: s__('Runners|Active') },
    { value: STATUS_PAUSED, title: s__('Runners|Paused') },
    { value: STATUS_ONLINE, title: s__('Runners|Online') },
    { value: STATUS_OFFLINE, title: s__('Runners|Offline') },

    // Added extra quotes in this title to avoid splitting this value:
    // see: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1438
    { value: STATUS_NOT_CONNECTED, title: `"${s__('Runners|Not connected')}"` },
  ],
  // TODO In principle we could support more complex search rules,
  // this can be added to a separate issue.
  operators: OPERATOR_IS_ONLY,
};
