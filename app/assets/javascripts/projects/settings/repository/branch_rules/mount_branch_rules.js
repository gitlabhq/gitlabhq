import Vue from 'vue';
import BranchRulesApp from '~/projects/settings/repository/branch_rules/app.vue';

export default function mountBranchRules(el) {
  if (!el) return null;

  return new Vue({
    el,
    render(createElement) {
      return createElement(BranchRulesApp);
    },
  });
}
