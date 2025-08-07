import Vue from 'vue';
import CollationChecker from './components/collation_checker_app.vue';

export const initDatabaseDiagnosticsApp = () => {
  const el = document.getElementById('js-database-diagnostics');

  if (!el) return false;

  const { runCollationCheckUrl, collationCheckResultsUrl } = el.dataset;

  return new Vue({
    el,
    name: 'DatabaseCollationHealthChecker',
    provide: {
      runCollationCheckUrl,
      collationCheckResultsUrl,
    },
    render(createElement) {
      return createElement(CollationChecker);
    },
  });
};
