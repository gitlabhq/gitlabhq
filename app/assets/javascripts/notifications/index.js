import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import NotificationsDropdown from './components/notifications_dropdown.vue';

Vue.use(GlToast);

export default () => {
  const containers = document.querySelectorAll('.js-vue-notification-dropdown');

  if (!containers.length) return false;

  return containers.forEach((el) => {
    const {
      containerClass,
      buttonSize,
      disabled,
      dropdownItems,
      notificationLevel,
      helpPagePath,
      projectId,
      groupId,
      showLabel,
    } = el.dataset;

    return new Vue({
      el,
      provide: {
        containerClass,
        buttonSize,
        disabled: parseBoolean(disabled),
        dropdownItems: JSON.parse(dropdownItems),
        initialNotificationLevel: notificationLevel,
        helpPagePath,
        projectId,
        groupId,
        showLabel: parseBoolean(showLabel),
      },
      render(h) {
        return h(NotificationsDropdown);
      },
    });
  });
};
