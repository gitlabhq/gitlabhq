import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { PARAM_KEY_VERSION, I18N_VERSION } from '../../constants';

export const versionTokenConfig = {
  icon: 'doc-versions',
  title: I18N_VERSION,
  type: PARAM_KEY_VERSION,
  token: BaseToken,
  operators: OPERATORS_IS,
  suggestionsDisabled: true,
};
