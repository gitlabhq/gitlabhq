import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DeployKeysApp from './components/app.vue';
import { createApolloProvider } from './graphql/client';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-deploy-keys');

  if (!el) return false;

  return initVueApp({
    el,
    name: 'DeployKeysAppRoot',
    apolloProvider: createApolloProvider({
      enabledKeysEndpoint: el.dataset.enabledEndpoint,
      availableProjectKeysEndpoint: el.dataset.availableProjectEndpoint,
      availablePublicKeysEndpoint: el.dataset.availablePublicEndpoint,
    }),
    component: DeployKeysApp,
    props: {
      projectId: el.dataset.projectId,
      projectPath: el.dataset.projectPath,
    },
  });
};
