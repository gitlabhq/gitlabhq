import $ from 'jquery';
import { Rails } from '~/lib/utils/rails_ujs';
import { deprecatedCreateFlash as Flash } from './flash';
import { __ } from '~/locale';

export default function notificationsDropdown() {
  $(document).on('click', '.update-notification', function updateNotificationCallback(e) {
    e.preventDefault();

    if ($(this).is('.is-active') && $(this).data('notificationLevel') === 'custom') {
      return;
    }

    const notificationLevel = $(this).data('notificationLevel');
    const form = $(this)
      .parents('.notification-form')
      .first();

    form.find('.js-notification-loading').toggleClass('spinner');
    if (form.hasClass('no-label')) {
      form.find('.js-notification-loading').toggleClass('hidden');
      form.find('.js-notifications-icon').toggleClass('hidden');
    }
    form.find('#notification_setting_level').val(notificationLevel);
    Rails.fire(form[0], 'submit');
  });

  $(document).on('ajax:success', '.notification-form', e => {
    const data = e.detail[0];

    if (data.saved) {
      $(e.currentTarget)
        .closest('.js-notification-dropdown')
        .replaceWith(data.html);
    } else {
      Flash(__('Failed to save new settings'), 'alert');
    }
  });
}
