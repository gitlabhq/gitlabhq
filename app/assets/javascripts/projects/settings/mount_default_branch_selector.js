import Vue from 'vue';
import DefaultBranchSelector from './components/default_branch_selector.vue';

export default (el) => {
  if (!el) {
    return null;
  }

  const { projectId, defaultBranch } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(DefaultBranchSelector, {
        props: {
          persistedDefaultBranch: defaultBranch,
          projectId,
        },
      });
    },
  });
};
