import initBlobShow from '~/blob/show/show_blob_bundle';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

if (gon.features?.vue3MigrateRepository) {
  (async () => {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { default: initBlobShow } = await import('~/blob/show/show_blob_bundle?vue3');
      initBlobShow();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }

    initBlobShow();
  })();
} else {
  initBlobShow();
}
