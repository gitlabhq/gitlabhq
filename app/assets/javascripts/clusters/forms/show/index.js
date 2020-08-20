import Vue from 'vue';
import IntegrationForm from '../components/integration_form.vue';
import { createStore } from '../stores';

export default () => {
  const entryPoint = document.querySelector('#js-cluster-integration-form');

  if (!entryPoint) {
    return;
  }

  const { autoDevopsHelpPath, externalEndpointHelpPath } = entryPoint.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: entryPoint,
    store: createStore(entryPoint.dataset),
    provide: {
      autoDevopsHelpPath,
      externalEndpointHelpPath,
    },

    render(createElement) {
      return createElement(IntegrationForm, {});
    },
  });
};
