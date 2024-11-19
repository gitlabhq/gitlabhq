import Vue from 'vue';
import BadgeSettings from '~/badges/components/badge_settings.vue';
import createStore from '~/badges/store';

export default (kind) => {
  const badgeSettingsElement = document.getElementById('badge-settings');

  if (!badgeSettingsElement) return null;

  return new Vue({
    el: badgeSettingsElement,
    store: createStore({
      kind,
      apiEndpointUrl: badgeSettingsElement.dataset.apiEndpointUrl,
      docsUrl: badgeSettingsElement.dataset.docsUrl,
    }),
    components: {
      BadgeSettings,
    },
    render(createElement) {
      return createElement(BadgeSettings);
    },
  });
};
