import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import NotificationsDropdown from './components/notifications_dropdown.vue';

Vue.use(GlToast);

export default () => {
  const el = document.querySelector('.js-vue-notification-dropdown');

  if (!el) return false;

  const {
    containerClass,
    buttonSize,
    disabled,
    dropdownItems,
    notificationLevel,
    projectId,
    groupId,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      containerClass,
      buttonSize,
      disabled: parseBoolean(disabled),
      dropdownItems: JSON.parse(dropdownItems),
      initialNotificationLevel: notificationLevel,
      projectId,
      groupId,
    },
    render(h) {
      return h(NotificationsDropdown);
    },
  });
};
