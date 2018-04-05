import $ from 'jquery';
import Flash from './flash';

export default function notificationsDropdown() {
  $(document).on('click', '.update-notification', function updateNotificationCallback(e) {
    e.preventDefault();
    if ($(this).is('.is-active') && $(this).data('notificationLevel') === 'custom') {
      return;
    }

    const notificationLevel = $(this).data('notificationLevel');
    const form = $(this).parents('.notification-form:first');

    form.find('.js-notification-loading').toggleClass('fa-bell fa-spin fa-spinner');
    form.find('#notification_setting_level').val(notificationLevel);
    form.submit();
  });

  $(document).on('ajax:success', '.notification-form', (e, data) => {
    if (data.saved) {
      $(e.currentTarget).closest('.js-notification-dropdown').replaceWith(data.html);
    } else {
      Flash('Failed to save new settings', 'alert');
    }
  });
}
