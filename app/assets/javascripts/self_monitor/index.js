import Vue from 'vue';
import store from './store';
import SelfMonitorForm from './components/self_monitor_form.vue';

export default () => {
  const el = document.querySelector('.js-self-monitoring-settings');
  let selfMonitorProjectCreated;

  if (el) {
    selfMonitorProjectCreated = el.dataset.selfMonitoringProjectExists;
    // eslint-disable-next-line no-new
    new Vue({
      el,
      store: store({
        projectEnabled: selfMonitorProjectCreated,
        ...el.dataset,
      }),
      render(createElement) {
        return createElement(SelfMonitorForm);
      },
    });
  }
};
