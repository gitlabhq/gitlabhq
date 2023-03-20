export default () => {
  const denyAllRequests = document.querySelector('.js-deny-all-requests');

  if (!denyAllRequests) {
    return;
  }

  denyAllRequests.addEventListener('change', () => {
    const denyAll = denyAllRequests.checked;
    const allowLocalRequests = document.querySelectorAll('.js-allow-local-requests');
    const denyAllRequestsWarning = document.querySelector('.js-deny-all-requests-warning');

    if (denyAll) {
      denyAllRequestsWarning.classList.remove('gl-display-none');
    } else {
      denyAllRequestsWarning.classList.add('gl-display-none');
    }

    allowLocalRequests.forEach((allowLocalRequest) => {
      /* eslint-disable no-param-reassign */
      if (denyAll) {
        allowLocalRequest.checked = false;
      }
      allowLocalRequest.disabled = denyAll;
      /* eslint-enable no-param-reassign */
    });
  });
};
