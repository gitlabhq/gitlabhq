import { initToggle } from '~/toggles';

function updateVisibility(selector, isVisible) {
  Array.from(document.querySelectorAll(selector)).forEach((el) => {
    if (isVisible) {
      el.classList.remove('!gl-hidden');
    } else {
      el.classList.add('!gl-hidden');
    }
  });
}

export default () => {
  const sslToggle = initToggle(document.querySelector('.js-enable-ssl-gl-toggle'));
  const sslToggleInput = document.querySelector('.js-project-feature-toggle-input');

  if (sslToggle) {
    sslToggle.$on('change', (isAutoSslEnabled) => {
      updateVisibility('.js-shown-unless-auto-ssl', !isAutoSslEnabled);
      updateVisibility('.js-shown-if-auto-ssl', isAutoSslEnabled);

      Array.from(document.querySelectorAll('.js-enabled-unless-auto-ssl')).forEach((el) => {
        if (isAutoSslEnabled) {
          el.setAttribute('disabled', 'disabled');
        } else {
          el.removeAttribute('disabled');
        }
      });

      sslToggleInput.setAttribute('value', isAutoSslEnabled);
    });
  }
  return sslToggle;
};
