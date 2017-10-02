import _ from 'underscore';

const hideFlash = (flashEl) => {
  flashEl.style.transition = 'opacity .3s'; // eslint-disable-line no-param-reassign
  flashEl.style.opacity = '0'; // eslint-disable-line no-param-reassign

  flashEl.addEventListener('transitionend', () => {
    flashEl.remove();
  }, {
    once: true,
  });
};

const createAction = config => `
  <a
    href="${config.href || '#'}"
    class="flash-action"
    ${config.href ? 'role="button"' : ''}
  >
    ${_.escape(config.title)}
  </a>
`;

const createFlashEl = (message, type) => `
  <div
    class="flash-${type}"
  >
    <div
      class="flash-text"
    >
      ${_.escape(message)}
    </div>
  </div>
`;

const Flash = function Flash(message, type = 'alert', parent = document, actionConfig = null) {
  const flashContainer = parent.querySelector('.flash-container');
  flashContainer.innerHTML = createFlashEl(message, type);

  const flashEl = flashContainer.querySelector(`.flash-${type}`);
  flashEl.addEventListener('click', () => hideFlash(flashEl));

  if (actionConfig) {
    flashEl.innerHTML += createAction(actionConfig);

    if (actionConfig.clickHandler) {
      flashEl.querySelector('.flash-action').addEventListener('click', e => actionConfig.clickHandler(e));
    }
  }

  if (flashContainer.parentNode.classList.contains('content-wrapper')) {
    const flashText = flashEl.querySelector('.flash-text');

    flashText.classList.add('container-fluid');
    flashText.classList.add('container-limited');
  }

  flashContainer.style.display = 'block';

  return flashContainer;
};

export {
  Flash as default,
  createFlashEl,
  hideFlash,
};
window.Flash = Flash;
