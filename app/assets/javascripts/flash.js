import _ from 'underscore';

const hideFlash = (flashEl) => {
  Object.assign(flashEl.style, {
    transition: 'opacity .3s',
    opacity: '0',
  });

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

const createFlash = function createFlash(message, type = 'alert', parent = document, actionConfig = null) {
  const flashContainer = parent.querySelector('.flash-container');

  if (!flashContainer) return null;

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
  createFlash as default,
  createFlashEl,
  hideFlash,
};
window.Flash = createFlash;
