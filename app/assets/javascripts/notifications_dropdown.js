this.NotificationsDropdown = (function() {
  function NotificationsDropdown() {
    $(document).off('click', '.update-notification').on('click', '.update-notification', function(e) {
      var form, label, notificationLevel;
      e.preventDefault();
      if ($(this).is('.is-active') && $(this).data('notification-level') === 'custom') {
        return;
      }
      notificationLevel = $(this).data('notification-level');
      label = $(this).data('notification-title');
      form = $(this).parents('.notification-form:first');
      form.find('.js-notification-loading').toggleClass('fa-bell fa-spin fa-spinner');
      form.find('#notification_setting_level').val(notificationLevel);
      return form.submit();
    });
    $(document).off('ajax:success', '.notification-form').on('ajax:success', '.notification-form', function(e, data) {
      if (data.saved) {
        return $(e.currentTarget).closest('.notification-dropdown').replaceWith(data.html);
      } else {
        return new Flash('Failed to save new settings', 'alert');
      }
    });
  }

  return NotificationsDropdown;

})();
