import Cookies from 'js-cookie';

const handleOnDismiss = ({ currentTarget }) => {
  const {
    dataset: { id, level },
  } = currentTarget;

  Cookies.set(`hide_storage_limit_alert_${id}_${level}`, true, { expires: 365 });

  const notification = document.querySelector('.js-namespace-storage-alert');
  notification.parentNode.removeChild(notification);
};

export default () => {
  const alert = document.querySelector('.js-namespace-storage-alert-dismiss');

  if (alert) {
    alert.addEventListener('click', handleOnDismiss);
  }
};
