import Vue from 'vue';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import IntegrationForm from '../components/integration_form.vue';
import { createStore } from '../stores';

export default () => {
  dirtySubmitFactory(document.querySelectorAll('.js-cluster-integrations-form'));

  const entryPoint = document.querySelector('#js-cluster-details-form');

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
