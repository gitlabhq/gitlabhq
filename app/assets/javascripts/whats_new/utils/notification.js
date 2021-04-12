export const STORAGE_KEY = 'display-whats-new-notification';

export const getVersionDigest = (appEl) => appEl.getAttribute('data-version-digest');

export const setNotification = (appEl) => {
  const versionDigest = getVersionDigest(appEl);
  const notificationEl = document.querySelector('.header-help');
  let notificationCountEl = notificationEl.querySelector('.js-whats-new-notification-count');

  const legacyStorageKey = 'display-whats-new-notification-13.10';
  const localStoragePairs = [
    [legacyStorageKey, false],
    [STORAGE_KEY, versionDigest],
  ];
  if (localStoragePairs.some((pair) => localStorage.getItem(pair[0]) === pair[1].toString())) {
    notificationEl.classList.remove('with-notifications');
    if (notificationCountEl) {
      notificationCountEl.parentElement.removeChild(notificationCountEl);
      notificationCountEl = null;
    }
  } else {
    notificationEl.classList.add('with-notifications');
  }
};
