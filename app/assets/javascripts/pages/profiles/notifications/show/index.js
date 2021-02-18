import initNotificationsDropdown from '~/notifications';
import notificationsDropdown from '../../../../notifications_dropdown';
import NotificationsForm from '../../../../notifications_form';

document.addEventListener('DOMContentLoaded', () => {
  new NotificationsForm(); // eslint-disable-line no-new
  notificationsDropdown();
  initNotificationsDropdown();
});
