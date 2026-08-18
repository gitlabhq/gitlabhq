import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import DefaultBranchSelector from './components/default_branch_selector.vue';

export default (el) => {
  if (!el) {
    return null;
  }

  const { projectId, defaultBranch, disabled } = el.dataset;

  return initVueApp({
    el,
    name: 'DefaultBranchSelectorRoot',
    component: DefaultBranchSelector,
    props: {
      disabled: parseBoolean(disabled),
      persistedDefaultBranch: defaultBranch,
      projectId,
    },
  });
};
