import Vue from 'vue';
import CombinedDiagnostics from './components/combined_diagnostics.vue';

export const initDatabaseDiagnosticsApp = () => {
  const el = document.getElementById('js-database-diagnostics');

  if (!el) return false;

  const {
    runCollationCheckUrl,
    collationCheckResultsUrl,
    runSchemaCheckUrl,
    schemaCheckResultsUrl,
  } = el.dataset;

  return new Vue({
    el,
    name: 'DatabaseDiagnosticsView',
    provide: {
      runCollationCheckUrl,
      collationCheckResultsUrl,
      runSchemaCheckUrl,
      schemaCheckResultsUrl,
    },
    render(createElement) {
      return createElement(CombinedDiagnostics);
    },
  });
};
