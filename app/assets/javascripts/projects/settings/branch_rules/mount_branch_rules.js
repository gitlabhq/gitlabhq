import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import RuleEdit from './components/edit/index.vue';

export default function mountBranchRules(el) {
  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { projectPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(RuleEdit, { props: { projectPath } });
    },
  });
}
