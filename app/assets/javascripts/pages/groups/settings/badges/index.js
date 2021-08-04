import Vue from 'vue';
import { GROUP_BADGE } from '~/badges/constants';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

mountBadgeSettings(GROUP_BADGE);
