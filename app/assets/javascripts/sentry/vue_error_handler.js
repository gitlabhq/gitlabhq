import * as Sentry from '~/sentry/sentry_browser_wrapper';

// Forwards Vue reactivity-boundary errors to Sentry. Without this, Vue
// swallows them in its internal handleError and they never reach
// window.onerror.
//
// This handler is only installed in production bundles (see commons/vue.js
// and lib/utils/vue3compat/vue.js). In development and Jest, Vue's default
// error path runs unchanged, preserving the formatted component-trace
// console output developers rely on.
export const vueErrorHandler = (err, vm, info) => {
  Sentry.captureException(err, {
    tags: { vue_error: 'true', vue_info: info },
    extra: { vue_component: vm?.$options?.name ?? 'unknown' },
  });
};
