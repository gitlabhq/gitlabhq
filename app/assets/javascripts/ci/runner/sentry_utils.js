import * as Sentry from '~/sentry/sentry_browser_wrapper';

const COMPONENT_TAG = 'vue_component';

/**
 * Captures an error in a Vue component and sends it
 * to Sentry
 *
 * @param {Object} options Exception details
 * @param {Object} options.error An exception-like object
 * @param {string} [options.component=] Component name in CamelCase format
 */
export const captureException = ({ error, component }) => {
  if (component) {
    Sentry.captureException(error, {
      tags: { [COMPONENT_TAG]: component },
    });
  } else {
    Sentry.captureException(error);
  }
};
