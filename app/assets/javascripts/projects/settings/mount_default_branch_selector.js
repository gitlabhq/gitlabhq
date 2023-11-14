import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import DefaultBranchSelector from './components/default_branch_selector.vue';

export default (el) => {
  if (!el) {
    return null;
  }

  const { projectId, defaultBranch, disabled } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(DefaultBranchSelector, {
        props: {
          disabled: parseBoolean(disabled),
          persistedDefaultBranch: defaultBranch,
          projectId,
        },
      });
    },
  });
};
