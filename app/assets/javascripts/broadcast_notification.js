import { setCookie } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from '~/api/api_utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const dismissUserBroadcastMessage = (id, expireDate, dismissalPath) => {
  return axios.post(buildApiUrl(dismissalPath), {
    broadcast_message_id: id,
    expires_at: expireDate,
  });
};

const handleOnDismiss = ({ currentTarget }) => {
  currentTarget.removeEventListener('click', handleOnDismiss);
  const {
    dataset: { id, expireDate, dismissalPath, cookieKey },
  } = currentTarget;

  setCookie(cookieKey, true, { expires: new Date(expireDate) });

  // Create db record to persist dismissal
  if (dismissalPath) {
    dismissUserBroadcastMessage(id, expireDate, dismissalPath).catch((e) =>
      Sentry.captureException(e),
    );
  }

  const notification = document.querySelector(`.js-broadcast-notification-${id}`);
  notification.parentNode.removeChild(notification);
};

export default () => {
  document
    .querySelectorAll('.js-dismiss-current-broadcast-notification')
    .forEach((dismissButton) => dismissButton.addEventListener('click', handleOnDismiss));
};
