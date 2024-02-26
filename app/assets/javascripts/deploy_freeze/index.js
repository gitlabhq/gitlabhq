import Vue from 'vue';
import DeployFreezeSettings from './components/deploy_freeze_settings.vue';
import createStore from './store';

export default () => {
  const el = document.getElementById('js-deploy-freeze-table');

  if (!el) {
    return null;
  }

  const { projectId, timezoneData } = el.dataset;

  const store = createStore({
    projectId,
    timezoneData: JSON.parse(timezoneData),
  });

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(DeployFreezeSettings);
    },
  });
};
