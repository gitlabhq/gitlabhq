import Cookies from 'js-cookie';

const handleOnDismiss = ({ currentTarget }) => {
  currentTarget.removeEventListener('click', handleOnDismiss);
  const {
    dataset: { id },
  } = currentTarget;

  Cookies.set(`hide_broadcast_notification_message_${id}`, true);

  const notification = document.querySelector(`.js-broadcast-notification-${id}`);
  notification.parentNode.removeChild(notification);
};

export default () => {
  const dismissButton = document.querySelector('.js-dismiss-current-broadcast-notification');

  if (dismissButton) {
    dismissButton.addEventListener('click', handleOnDismiss);
  }
};
