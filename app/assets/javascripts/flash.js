import _ from 'underscore';
import { spriteIcon } from './lib/utils/common_utils';

const hideFlash = (flashEl, fadeTransition = true) => {
  if (fadeTransition) {
    Object.assign(flashEl.style, {
      transition: 'opacity .3s',
      opacity: '0',
    });
  }

  flashEl.addEventListener(
    'transitionend',
    () => {
      flashEl.remove();
      window.dispatchEvent(new Event('resize'));
      if (document.body.classList.contains('flash-shown'))
        document.body.classList.remove('flash-shown');
    },
    {
      once: true,
      passive: true,
    },
  );

  if (!fadeTransition) flashEl.dispatchEvent(new Event('transitionend'));
};

const createAction = config => `
  <a
    href="${config.href || '#'}"
    class="flash-action"
    ${config.href ? '' : 'role="button"'}
  >
    ${_.escape(config.title)}
  </a>
`;

const createFlashEl = (message, type) => `
  <div class="flash-${type}">
    <div class="flash-text">
      ${_.escape(message)}
      <div class="close-icon-wrapper js-close-icon">
        ${spriteIcon('close', 'close-icon')}
      </div>
    </div>
  </div>
`;

const removeFlashClickListener = (flashEl, fadeTransition) => {
  flashEl
    .querySelector('.js-close-icon')
    .addEventListener('click', () => hideFlash(flashEl, fadeTransition));
};

/*
 *  Flash banner supports different types of Flash configurations
 *  along with ability to provide actionConfig which can be used to show
 *  additional action or link on banner next to message
 *
 *  @param {String} message           Flash message text
 *  @param {String} type              Type of Flash, it can be `notice` or `alert` (default)
 *  @param {Object} parent            Reference to parent element under which Flash needs to appear
 *  @param {Object} actonConfig       Map of config to show action on banner
 *    @param {String} href            URL to which action config should point to (default: '#')
 *    @param {String} title           Title of action
 *    @param {Function} clickHandler  Method to call when action is clicked on
 *  @param {Boolean} fadeTransition   Boolean to determine whether to fade the alert out
 */
const createFlash = function createFlash(
  message,
  type = 'alert',
  parent = document,
  actionConfig = null,
  fadeTransition = true,
  addBodyClass = false,
) {
  const flashContainer = parent.querySelector('.flash-container');

  if (!flashContainer) return null;

  flashContainer.innerHTML = createFlashEl(message, type);

  const flashEl = flashContainer.querySelector(`.flash-${type}`);

  if (actionConfig) {
    flashEl.innerHTML += createAction(actionConfig);

    if (actionConfig.clickHandler) {
      flashEl
        .querySelector('.flash-action')
        .addEventListener('click', e => actionConfig.clickHandler(e));
    }
  }

  removeFlashClickListener(flashEl, fadeTransition);

  flashContainer.style.display = 'block';

  if (addBodyClass) document.body.classList.add('flash-shown');

  return flashContainer;
};

export { createFlash as default, createFlashEl, createAction, hideFlash, removeFlashClickListener };
window.Flash = createFlash;
