import { s__ } from '~/locale';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { PARAM_KEY_TAG } from '../../constants';
import TagToken from './tag_token.vue';

export const tagTokenConfig = {
  icon: 'tag',
  title: s__('Runners|Tags'),
  type: PARAM_KEY_TAG,
  token: TagToken,
  operators: OPERATORS_IS,
};
