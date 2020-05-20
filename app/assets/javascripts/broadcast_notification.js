import Cookies from 'js-cookie';

const handleOnDismiss = ({ currentTarget }) => {
  currentTarget.removeEventListener('click', handleOnDismiss);
  const {
    dataset: { id, expireDate },
  } = currentTarget;

  Cookies.set(`hide_broadcast_message_${id}`, true, { expires: new Date(expireDate) });

  const notification = document.querySelector(`.js-broadcast-notification-${id}`);
  notification.parentNode.removeChild(notification);
};

export default () => {
  document
    .querySelectorAll('.js-dismiss-current-broadcast-notification')
    .forEach(dismissButton => dismissButton.addEventListener('click', handleOnDismiss));
};
