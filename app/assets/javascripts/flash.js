import * as Sentry from '@sentry/browser';
import { escape } from 'lodash';
import Vue from 'vue';
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import { spriteIcon } from './lib/utils/common_utils';

const FLASH_TYPES = {
  ALERT: 'alert',
  NOTICE: 'notice',
  SUCCESS: 'success',
  WARNING: 'warning',
};

const VARIANT_SUCCESS = 'success';
const VARIANT_WARNING = 'warning';
const VARIANT_DANGER = 'danger';
const VARIANT_INFO = 'info';
const VARIANT_TIP = 'tip';

const TYPE_TO_VARIANT = {
  [FLASH_TYPES.ALERT]: VARIANT_DANGER,
  [FLASH_TYPES.NOTICE]: VARIANT_INFO,
  [FLASH_TYPES.SUCCESS]: VARIANT_SUCCESS,
  [FLASH_TYPES.WARNING]: VARIANT_WARNING,
};

const FLASH_CLOSED_EVENT = 'flashClosed';

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
      flashEl.dispatchEvent(new Event(FLASH_CLOSED_EVENT));
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
  <div class="flash-${type}" data-testid="alert-${TYPE_TO_VARIANT[type]}">
    <div class="flash-text">
      ${escape(message)}
      <div class="close-icon-wrapper js-close-icon">
        ${spriteIcon('close', 'close-icon')}
      </div>
    </div>
  </div>
`;

const addDismissFlashClickListener = (flashEl, fadeTransition) => {
  // There are some flash elements which do not have a closeEl.
  // https://gitlab.com/gitlab-org/gitlab/blob/763426ef344488972eb63ea5be8744e0f8459e6b/ee/app/views/layouts/header/_read_only_banner.html.haml
  getCloseEl(flashEl)?.addEventListener('click', () => hideFlash(flashEl, fadeTransition));
};

/**
 * Render an alert at the top of the page, or, optionally an
 * arbitrary existing container. This alert is always dismissible.
 *
 * @example
 * // Render a new alert
 * import { createAlert, VARIANT_WARNING } from '~/flash';
 *
 * createAlert({ message: 'My error message' });
 * createAlert({ message: 'My warning message', variant: VARIANT_WARNING });
 *
 * @example
 * // Dismiss this alert programmatically
 * const alert = createAlert({ message: 'Message' });
 *
 * // ...
 *
 * alert.dismiss();
 *
 * @example
 * // Respond to the alert being dismissed
 * createAlert({ message: 'Message', onDismiss: () => {} });
 *
 * @param {object} options - Options to control the flash message
 * @param {string} options.message - Alert message text
 * @param {string} [options.title] - Alert title
 * @param {VARIANT_SUCCESS|VARIANT_WARNING|VARIANT_DANGER|VARIANT_INFO|VARIANT_TIP} [options.variant] - Which GlAlert variant to use; it defaults to VARIANT_DANGER.
 * @param {object} [options.parent] - Reference to parent element under which alert needs to appear. Defaults to `document`.
 * @param {Function} [options.onDismiss] - Handler to call when this alert is dismissed.
 * @param {string} [options.containerSelector] - Selector for the container of the alert
 * @param {boolean} [options.preservePrevious] - Set to `true` to preserve previous alerts. Defaults to `false`.
 * @param {object} [options.primaryButton] - Object describing primary button of alert
 * @param {string} [options.primaryButton.link] - Href of primary button
 * @param {string} [options.primaryButton.text] - Text of primary button
 * @param {Function} [options.primaryButton.clickHandler] - Handler to call when primary button is clicked on. The click event is sent as an argument.
 * @param {object} [options.secondaryButton] - Object describing secondary button of alert
 * @param {string} [options.secondaryButton.link] - Href of secondary button
 * @param {string} [options.secondaryButton.text] - Text of secondary button
 * @param {Function} [options.secondaryButton.clickHandler] - Handler to call when secondary button is clicked on. The click event is sent as an argument.
 * @param {boolean} [options.captureError] - Whether to send error to Sentry
 * @param {object} [options.error] - Error to be captured in Sentry
 */
const createAlert = function createAlert({
  message,
  title,
  variant = VARIANT_DANGER,
  parent = document,
  containerSelector = '.flash-container',
  preservePrevious = false,
  primaryButton = null,
  secondaryButton = null,
  onDismiss = null,
  captureError = false,
  error = null,
}) {
  if (captureError && error) Sentry.captureException(error);

  const alertContainer = parent.querySelector(containerSelector);
  if (!alertContainer) return null;

  const el = document.createElement('div');
  if (preservePrevious) {
    alertContainer.appendChild(el);
  } else {
    alertContainer.replaceChildren(el);
  }

  return new Vue({
    el,
    components: {
      GlAlert,
    },
    methods: {
      /**
       * Public method to dismiss this alert and removes
       * this Vue instance.
       */
      dismiss() {
        if (onDismiss) {
          onDismiss();
        }
        this.$destroy();
        this.$el.parentNode?.removeChild(this.$el);
      },
    },
    render(h) {
      const on = {};

      on.dismiss = () => {
        this.dismiss();
      };

      if (primaryButton?.clickHandler) {
        on.primaryAction = (e) => {
          primaryButton.clickHandler(e);
        };
      }
      if (secondaryButton?.clickHandler) {
        on.secondaryAction = (e) => {
          secondaryButton.clickHandler(e);
        };
      }

      return h(
        GlAlert,
        {
          props: {
            title,
            dismissible: true,
            dismissLabel: __('Dismiss'),
            variant,
            primaryButtonLink: primaryButton?.link,
            primaryButtonText: primaryButton?.text,
            secondaryButtonLink: secondaryButton?.link,
            secondaryButtonText: secondaryButton?.text,
          },
          attrs: {
            'data-testid': `alert-${variant}`,
          },
          on,
        },
        message,
      );
    },
  });
};

/**
 * @deprecated use `createAlert` instead
 *
 * Flash banner supports different types of Flash configurations
 * along with ability to provide actionConfig which can be used to show
 * additional action or link on banner next to message
 *
 * @param {object} options - Options to control the flash message
 * @param {string} options.message - Flash message text
 * @param {'alert'|'notice'|'success'|'warning'} [options.type] - Type of Flash; it defaults to 'alert'
 * @param {Element|Document} [options.parent] - Reference to parent element under which Flash needs to appear
 * @param {object} [options.actionConfig] - Map of config to show action on banner
 * @param {string} [options.actionConfig.href] - URL to which action config should point to (default: '#')
 * @param {string} [options.actionConfig.title] - Title of action
 * @param {Function} [options.actionConfig.clickHandler] - Method to call when action is clicked on
 * @param {boolean} [options.fadeTransition] - Boolean to determine whether to fade the alert out
 * @param {boolean} [options.addBodyClass] - Adds `flash-shown` class to the `body` element
 * @param {boolean} [options.captureError] - Boolean to determine whether to send error to Sentry
 * @param {object} [options.error] - Error to be captured in Sentry
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

  // eslint-disable-next-line no-unsanitized/property
  flashContainer.innerHTML = createFlashEl(message, type);

  const flashEl = flashContainer.querySelector(`.flash-${type}`);

  if (actionConfig) {
    // eslint-disable-next-line no-unsanitized/method
    flashEl.insertAdjacentHTML('beforeend', createAction(actionConfig));

    if (actionConfig.clickHandler) {
      flashEl
        .querySelector('.flash-action')
        .addEventListener('click', (e) => actionConfig.clickHandler(e));
    }
  }

  addDismissFlashClickListener(flashEl, fadeTransition);

  flashContainer.classList.add('gl-display-block');

  if (addBodyClass) document.body.classList.add('flash-shown');

  if (captureError && error) Sentry.captureException(error);

  flashContainer.close = () => {
    getCloseEl(flashEl).click();
  };

  return flashContainer;
};

export {
  createFlash as default,
  hideFlash,
  addDismissFlashClickListener,
  FLASH_TYPES,
  FLASH_CLOSED_EVENT,
  createAlert,
  VARIANT_SUCCESS,
  VARIANT_WARNING,
  VARIANT_DANGER,
  VARIANT_INFO,
  VARIANT_TIP,
};
