export const STORAGE_KEY = 'display-whats-new-notification';

export const getVersionDigest = (appEl) => appEl.dataset.versionDigest;

export const setNotification = (appEl) => {
  const versionDigest = getVersionDigest(appEl);
  const notificationEl = document.querySelector('.header-help');
  if (!notificationEl) return;

  let notificationCountEl = notificationEl.querySelector('.js-whats-new-notification-count');

  if (localStorage.getItem(STORAGE_KEY) === versionDigest) {
    notificationEl.classList.remove('with-notifications');
    if (notificationCountEl) {
      notificationCountEl.parentElement.removeChild(notificationCountEl);
      notificationCountEl = null;
    }
  } else {
    notificationEl.classList.add('with-notifications');
  }
};
