import Vue from 'vue';
import store from './store';
import ExternalDashboardForm from './components/external_dashboard.vue';

export default () => {
  const el = document.querySelector('.js-operation-settings');

  return new Vue({
    el,
    store: store(el.dataset),
    render(createElement) {
      return createElement(ExternalDashboardForm);
    },
  });
};
