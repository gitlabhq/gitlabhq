export const getStorageKey = (appEl) => appEl.getAttribute('data-storage-key');

export const setNotification = (appEl) => {
  const storageKey = getStorageKey(appEl);
  const notificationEl = document.querySelector('.header-help');
  let notificationCountEl = notificationEl.querySelector('.js-whats-new-notification-count');

  if (JSON.parse(localStorage.getItem(storageKey)) === false) {
    notificationEl.classList.remove('with-notifications');
    if (notificationCountEl) {
      notificationCountEl.parentElement.removeChild(notificationCountEl);
      notificationCountEl = null;
    }
  } else {
    notificationEl.classList.add('with-notifications');
  }
};
