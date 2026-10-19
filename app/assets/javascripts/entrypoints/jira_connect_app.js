import { initJiraConnect } from '~/jira_connect/subscriptions';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

if (gon.features?.vue3MigrateJiraConnectApp) {
  (async () => {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initJiraConnect } = await import('~/jira_connect/subscriptions?vue3');
      initJiraConnect();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }

    initJiraConnect();
  })();
} else {
  initJiraConnect();
}
