import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import BadgeSettings from '~/badges/components/badge_settings.vue';
import createStore from '~/badges/store';

export default (kind) => {
  const badgeSettingsElement = document.getElementById('badge-settings');

  if (!badgeSettingsElement) return null;

  return initVueApp({
    el: badgeSettingsElement,
    name: 'BadgeSettingsRoot',
    store: createStore({
      kind,
      apiEndpointUrl: badgeSettingsElement.dataset.apiEndpointUrl,
      docsUrl: badgeSettingsElement.dataset.docsUrl,
    }),
    component: BadgeSettings,
  });
};
