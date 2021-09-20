import { __, s__ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE, PARAM_KEY_RUNNER_TYPE } from '../../constants';

export const typeTokenConfig = {
  icon: 'file-tree',
  title: __('Type'),
  type: PARAM_KEY_RUNNER_TYPE,
  token: BaseToken,
  unique: true,
  options: [
    { value: INSTANCE_TYPE, title: s__('Runners|instance') },
    { value: GROUP_TYPE, title: s__('Runners|group') },
    { value: PROJECT_TYPE, title: s__('Runners|project') },
  ],
  // TODO We should support more complex search rules,
  // search for multiple states (OR) or have NOT operators
  operators: OPERATOR_IS_ONLY,
};
