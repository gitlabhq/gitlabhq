import Vue from 'vue';
import VueApollo from 'vue-apollo';
import DeployKeysApp from './components/app.vue';
import { createApolloProvider } from './graphql/client';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-deploy-keys');

  if (!el) return false;

  return new Vue({
    el,
    apolloProvider: createApolloProvider({
      enabledKeysEndpoint: el.dataset.enabledEndpoint,
      availableProjectKeysEndpoint: el.dataset.availableProjectEndpoint,
      availablePublicKeysEndpoint: el.dataset.availablePublicEndpoint,
    }),
    render(createElement) {
      return createElement(DeployKeysApp, {
        props: {
          projectId: el.dataset.projectId,
          projectPath: el.dataset.projectPath,
        },
      });
    },
  });
};
