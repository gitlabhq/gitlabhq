import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { generateCacheConfig, resolvers } from '../ci_variable_list/graphql/settings';
import InheritedCiVariables from './components/inherited_ci_variables_app.vue';

export default (containerId = 'js-inherited-group-ci-variables') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return;
  }

  const { projectPath } = el.dataset;

  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      resolvers,
      generateCacheConfig(false), // set to true if we're using key-set pagination
    ),
  });

  // eslint-disable-next-line consistent-return
  return new Vue({
    el,
    apolloProvider,
    provide: {
      isInheritedGroupVars: true,
      projectPath,
    },
    render(createElement) {
      return createElement(InheritedCiVariables);
    },
  });
};
