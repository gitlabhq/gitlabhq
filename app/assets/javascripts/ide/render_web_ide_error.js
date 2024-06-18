import Vue from 'vue';
import { logError } from '~/lib/logger';
import WebIdeError from '~/ide/components/web_ide_error.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

export function renderWebIdeError({ error, signOutPath }) {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  logError('Failed to load Web IDE', error);
  Sentry.captureException(error);

  const alertContainer = document.querySelector('.flash-container');
  if (!alertContainer) return null;

  const el = document.createElement('div');
  alertContainer.appendChild(el);

  return new Vue({
    el,
    render(createElement) {
      return createElement(WebIdeError, { props: { signOutPath } });
    },
  });
}
