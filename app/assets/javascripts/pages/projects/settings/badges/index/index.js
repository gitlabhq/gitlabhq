import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { PROJECT_BADGE } from '~/badges/constants';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';

Vue.use(Translate);

document.addEventListener('DOMContentLoaded', () => {
  mountBadgeSettings(PROJECT_BADGE);
});
