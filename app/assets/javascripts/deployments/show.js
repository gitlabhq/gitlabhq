import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import ShowDeployment from './components/show_deployment.vue';

Vue.use(VueApollo);

export const initializeShowDeployment = (selector = 'js-deployment-details') => {
  const el = document.getElementById(selector);
  if (el) {
    const apolloProvider = new VueApollo({
      defaultClient: createDefaultClient(),
    });
    const { projectPath, deploymentIid, environmentName, graphqlEtagKey } = el.dataset;

    return initVueApp({
      el,
      name: 'ShowDeploymentRoot',
      apolloProvider,
      provide: {
        projectPath,
        deploymentIid,
        environmentName,
        graphqlEtagKey,
      },
      component: ShowDeployment,
    });
  }

  return null;
};
