import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import NotificationsDropdown from './components/notifications_dropdown.vue';
import NotificationEmailListboxInput from './components/notification_email_listbox_input.vue';

Vue.use(GlToast);

const initNotificationEmailListboxInputs = () => {
  const els = [...document.querySelectorAll('.js-notification-email-listbox-input')];

  els.forEach((el, index) => {
    const { label, name, emptyValueText, value = '' } = el.dataset;

    return new Vue({
      el,
      name: `NotificationEmailListboxInputRoot${index + 1}`,
      provide: {
        label,
        name,
        emails: JSON.parse(el.dataset.emails),
        emptyValueText,
        value,
        disabled: parseBoolean(el.dataset.disabled),
      },
      render(h) {
        return h(NotificationEmailListboxInput);
      },
    });
  });
};

export default () => {
  initNotificationEmailListboxInputs();

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
      noFlip,
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
        noFlip: parseBoolean(noFlip),
      },
      render(h) {
        return h(NotificationsDropdown);
      },
    });
  });
};
