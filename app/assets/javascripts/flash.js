import * as Sentry from '@sentry/browser';
import { escape } from 'lodash';
import { spriteIcon } from './lib/utils/common_utils';

const FLASH_TYPES = {
  ALERT: 'alert',
  NOTICE: 'notice',
  SUCCESS: 'success',
  WARNING: 'warning',
};

const getCloseEl = (flashEl) => {
  return flashEl.querySelector('.js-close-icon');
};

const hideFlash = (flashEl, fadeTransition = true) => {
  if (fadeTransition) {
    Object.assign(flashEl.style, {
      transition: 'opacity 0.15s',
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

const createAction = (config) => `
  <a
    href="${config.href || '#'}"
    class="flash-action"
    ${config.href ? '' : 'role="button"'}
  >
    ${escape(config.title)}
  </a>
`;

const createFlashEl = (message, type) => `
  <div class="flash-${type}">
    <div class="flash-text">
      ${escape(message)}
      <div class="close-icon-wrapper js-close-icon">
        ${spriteIcon('close', 'close-icon')}
      </div>
    </div>
  </div>
`;

const removeFlashClickListener = (flashEl, fadeTransition) => {
  getCloseEl(flashEl).addEventListener('click', () => hideFlash(flashEl, fadeTransition));
};

/*
 *  Flash banner supports different types of Flash configurations
 *  along with ability to provide actionConfig which can be used to show
 *  additional action or link on banner next to message
 *
 *  @param {Object} options                   Options to control the flash message
 *  @param {String} options.message           Flash message text
 *  @param {String} options.type              Type of Flash, it can be `notice`, `success`, `warning` or `alert` (default)
 *  @param {Object} options.parent            Reference to parent element under which Flash needs to appear
 *  @param {Object} options.actionConfig      Map of config to show action on banner
 *    @param {String} href                    URL to which action config should point to (default: '#')
 *    @param {String} title                   Title of action
 *    @param {Function} clickHandler          Method to call when action is clicked on
 *  @param {Boolean} options.fadeTransition   Boolean to determine whether to fade the alert out
 *  @param {Boolean} options.captureError     Boolean to determine whether to send error to sentry
 *  @param {Object} options.error              Error to be captured in sentry
 */
const createFlash = function createFlash({
  message,
  type = FLASH_TYPES.ALERT,
  parent = document,
  actionConfig = null,
  fadeTransition = true,
  addBodyClass = false,
  captureError = false,
  error = null,
}) {
  const flashContainer = parent.querySelector('.flash-container');

  if (!flashContainer) return null;

  flashContainer.innerHTML = createFlashEl(message, type);

  const flashEl = flashContainer.querySelector(`.flash-${type}`);

  if (actionConfig) {
    flashEl.insertAdjacentHTML('beforeend', createAction(actionConfig));

    if (actionConfig.clickHandler) {
      flashEl
        .querySelector('.flash-action')
        .addEventListener('click', (e) => actionConfig.clickHandler(e));
    }
  }

  removeFlashClickListener(flashEl, fadeTransition);

  flashContainer.classList.add('gl-display-block');

  if (addBodyClass) document.body.classList.add('flash-shown');

  if (captureError && error) Sentry.captureException(error);

  flashContainer.close = () => {
    getCloseEl(flashEl).click();
  };

  return flashContainer;
};

/*
 *  Flash banner supports different types of Flash configurations
 *  along with ability to provide actionConfig which can be used to show
 *  additional action or link on banner next to message
 *
 *  @param {String} message           Flash message text
 *  @param {String} type              Type of Flash, it can be `notice`, `success`, `warning` or `alert` (default)
 *  @param {Object} parent            Reference to parent element under which Flash needs to appear
 *  @param {Object} actionConfig      Map of config to show action on banner
 *    @param {String} href            URL to which action config should point to (default: '#')
 *    @param {String} title           Title of action
 *    @param {Function} clickHandler  Method to call when action is clicked on
 *  @param {Boolean} fadeTransition   Boolean to determine whether to fade the alert out
 */
const deprecatedCreateFlash = function deprecatedCreateFlash(
  message,
  type,
  parent,
  actionConfig,
  fadeTransition,
  addBodyClass,
) {
  return createFlash({ message, type, parent, actionConfig, fadeTransition, addBodyClass });
};

export {
  createFlash as default,
  deprecatedCreateFlash,
  createFlashEl,
  createAction,
  hideFlash,
  removeFlashClickListener,
  FLASH_TYPES,
};
window.Flash = createFlash;
