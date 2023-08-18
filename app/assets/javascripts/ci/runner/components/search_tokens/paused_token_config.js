import { __ } from '~/locale';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { PARAM_KEY_PAUSED, I18N_PAUSED } from '../../constants';

export const pausedTokenConfig = {
  icon: 'pause',
  title: I18N_PAUSED,
  type: PARAM_KEY_PAUSED,
  token: BaseToken,
  unique: true,
  options: [
    { value: 'true', title: __('Yes') },
    { value: 'false', title: __('No') },
  ],
  operators: OPERATORS_IS,
};
