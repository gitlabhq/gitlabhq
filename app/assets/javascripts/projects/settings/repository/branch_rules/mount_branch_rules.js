import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import BranchRulesApp from '~/projects/settings/repository/branch_rules/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default function mountBranchRules(el) {
  if (!el) return null;

  const { projectPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(BranchRulesApp, {
        props: {
          projectPath,
        },
      });
    },
  });
}
