import Vue from 'vue';
import IntegrationForm from '../components/integration_form.vue';
import { createStore } from '../stores';

export default () => {
  const entryPoint = document.querySelector('#js-cluster-integration-form');

  if (!entryPoint) {
    return;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el: entryPoint,
    store: createStore(entryPoint.dataset),

    render(createElement) {
      return createElement(IntegrationForm);
    },
  });
};
