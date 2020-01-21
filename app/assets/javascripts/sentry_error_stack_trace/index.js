import Vue from 'vue';
import SentryErrorStackTrace from './components/sentry_error_stack_trace.vue';
import store from '~/error_tracking/store';

export default function initSentryErrorStacktrace() {
  const sentryErrorStackTraceEl = document.querySelector('#js-sentry-error-stack-trace');
  if (sentryErrorStackTraceEl) {
    const { issueStackTracePath } = sentryErrorStackTraceEl.dataset;
    // eslint-disable-next-line no-new
    new Vue({
      el: sentryErrorStackTraceEl,
      components: {
        SentryErrorStackTrace,
      },
      store,
      render: createElement =>
        createElement('sentry-error-stack-trace', {
          props: { issueStackTracePath },
        }),
    });
  }
}
