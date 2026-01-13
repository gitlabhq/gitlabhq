import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import GroupToken from '~/vue_shared/components/filtered_search_bar/tokens/group_token.vue';
import { PARAM_KEY_GROUP, I18N_GROUP } from '~/ci/runner/constants';

export const groupTokenConfig = {
  icon: 'group',
  title: I18N_GROUP,
  type: PARAM_KEY_GROUP,
  token: GroupToken,
  operators: OPERATORS_IS,
  unique: true,
};
