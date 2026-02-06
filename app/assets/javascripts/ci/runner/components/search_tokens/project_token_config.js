import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import ProjectToken from '~/vue_shared/components/filtered_search_bar/tokens/project_token.vue';
import { PARAM_KEY_PROJECT, I18N_PROJECT } from '~/ci/runner/constants';

export const projectTokenConfig = {
  icon: 'project',
  title: I18N_PROJECT,
  type: PARAM_KEY_PROJECT,
  token: ProjectToken,
  operators: OPERATORS_IS,
  unique: true,
};
