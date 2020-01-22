import Vue from 'vue';
import store from './store';
import SelfMonitorForm from './components/self_monitor_form.vue';

export default () => {
  const el = document.querySelector('.js-self-monitoring-settings');

  if (el) {
    // eslint-disable-next-line no-new
    new Vue({
      el,
      store: store({
        ...el.dataset,
      }),
      render(createElement) {
        return createElement(SelfMonitorForm);
      },
    });
  }
};
