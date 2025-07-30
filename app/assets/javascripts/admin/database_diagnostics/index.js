import Vue from 'vue';
import CollationChecker from './components/collation_checker.vue';

export const initDatabaseDiagnosticsApp = () => {
  const el = document.getElementById('js-database-diagnostics');

  if (!el) {
    return false;
  }

  const { runCollationCheckUrl, collationCheckResultsUrl } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(CollationChecker, {
        props: {
          runCollationCheckUrl,
          collationCheckResultsUrl,
        },
      });
    },
  });
};
