import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import IntegrationForm from '../components/integration_form.vue';
import { createStore } from '../stores';

export default () => {
  const entryPoint = document.querySelector('#js-cluster-details-form');

  if (!entryPoint) {
    return;
  }

  const { autoDevopsHelpPath, externalEndpointHelpPath } = entryPoint.dataset;

  initVueApp({
    el: entryPoint,
    name: 'ClustersIntegrationFormRoot',
    store: createStore(entryPoint.dataset),
    provide: {
      autoDevopsHelpPath,
      externalEndpointHelpPath,
    },
    component: IntegrationForm,
  });
};
