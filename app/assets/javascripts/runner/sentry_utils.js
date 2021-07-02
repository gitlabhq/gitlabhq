import * as Sentry from '@sentry/browser';

const COMPONENT_TAG = 'vue_component';

/**
 * Captures an error in a Vue component and sends it
 * to Sentry
 *
 * @param {Object} options
 * @param {Error} options.error - Exception or error
 * @param {String} options.component - Component name in CamelCase format
 */
export const captureException = ({ error, component }) => {
  Sentry.withScope((scope) => {
    if (component) {
      scope.setTag(COMPONENT_TAG, component);
    }
    Sentry.captureException(error);
  });
};
