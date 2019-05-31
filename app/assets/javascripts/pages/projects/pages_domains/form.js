import setupToggleButtons from '~/toggle_buttons';

export default () => {
  const toggleContainer = document.querySelector('.js-auto-ssl-toggle-container');

  if (toggleContainer) {
    const onToggleButtonClicked = isAutoSslEnabled => {
      Array.from(document.querySelectorAll('.js-shown-if-auto-ssl')).forEach(el => {
        if (isAutoSslEnabled) {
          el.classList.remove('d-none');
        } else {
          el.classList.add('d-none');
        }
      });

      Array.from(document.querySelectorAll('.js-shown-unless-auto-ssl')).forEach(el => {
        if (isAutoSslEnabled) {
          el.classList.add('d-none');
        } else {
          el.classList.remove('d-none');
        }
      });

      Array.from(document.querySelectorAll('.js-enabled-if-auto-ssl')).forEach(el => {
        if (isAutoSslEnabled) {
          el.removeAttribute('disabled');
        } else {
          el.setAttribute('disabled', 'disabled');
        }
      });

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
