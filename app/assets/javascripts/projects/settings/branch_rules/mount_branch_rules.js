import Vue from 'vue';
import RuleEdit from './components/rule_edit.vue';

export default function mountBranchRules(el) {
  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render(h) {
      return h(RuleEdit);
    },
  });
}
