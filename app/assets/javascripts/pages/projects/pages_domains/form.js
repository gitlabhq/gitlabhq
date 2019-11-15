import setupToggleButtons from '~/toggle_buttons';

function updateVisibility(selector, isVisible) {
  Array.from(document.querySelectorAll(selector)).forEach(el => {
    if (isVisible) {
      el.classList.remove('d-none');
    } else {
      el.classList.add('d-none');
    }
  });
}

export default () => {
  const toggleContainer = document.querySelector('.js-auto-ssl-toggle-container');

  if (toggleContainer) {
    const onToggleButtonClicked = isAutoSslEnabled => {
      updateVisibility('.js-shown-unless-auto-ssl', !isAutoSslEnabled);

      updateVisibility('.js-shown-if-auto-ssl', isAutoSslEnabled);

      Array.from(document.querySelectorAll('.js-enabled-unless-auto-ssl')).forEach(el => {
        if (isAutoSslEnabled) {
          el.setAttribute('disabled', 'disabled');
        } else {
          el.removeAttribute('disabled');
        }
      });
    };

    setupToggleButtons(toggleContainer, onToggleButtonClicked);
  }
};
