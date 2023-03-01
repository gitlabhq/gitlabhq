import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';

export const VARIANT_SUCCESS = 'success';
export const VARIANT_WARNING = 'warning';
export const VARIANT_DANGER = 'danger';
export const VARIANT_INFO = 'info';
export const VARIANT_TIP = 'tip';

/**
 * Render an alert at the top of the page, or, optionally an
 * arbitrary existing container. This alert is always dismissible.
 *
 * @example
 * // Render a new alert
 * import { createAlert, VARIANT_WARNING } from '~/alert';
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
export const createAlert = ({
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
}) => {
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
