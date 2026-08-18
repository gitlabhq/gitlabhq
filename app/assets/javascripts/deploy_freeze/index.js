import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  return initVueApp({
    el,
    name: 'DeployFreezeSettingsRoot',
    store,
    component: DeployFreezeSettings,
  });
};
