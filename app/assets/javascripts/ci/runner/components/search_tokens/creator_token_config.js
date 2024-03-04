import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import { PARAM_KEY_CREATOR, I18N_CREATOR } from '../../constants';

export const creatorTokenConfig = {
  icon: 'user',
  title: I18N_CREATOR,
  type: PARAM_KEY_CREATOR,
  token: UserToken,
  dataType: 'user',
  operators: OPERATORS_IS,
};
