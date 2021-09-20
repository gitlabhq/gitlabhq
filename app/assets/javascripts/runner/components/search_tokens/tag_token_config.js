import { s__ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import { PARAM_KEY_TAG } from '../../constants';
import TagToken from './tag_token.vue';

export const tagTokenConfig = {
  icon: 'tag',
  title: s__('Runners|Tags'),
  type: PARAM_KEY_TAG,
  token: TagToken,
  operators: OPERATOR_IS_ONLY,
};
