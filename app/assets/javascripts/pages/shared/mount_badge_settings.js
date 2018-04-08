import Vue from 'vue';
import BadgeSettings from '~/badges/components/badge_settings.vue';
import store from '~/badges/store';

export default kind => {
  const badgeSettingsElement = document.getElementById('badge-settings');

  store.dispatch('loadBadges', {
    kind,
    apiEndpointUrl: badgeSettingsElement.dataset.apiEndpointUrl,
    docsUrl: badgeSettingsElement.dataset.docsUrl,
  });

  return new Vue({
    el: badgeSettingsElement,
    store,
    components: {
      BadgeSettings,
    },
    render(createElement) {
      return createElement(BadgeSettings);
    },
  });
};
