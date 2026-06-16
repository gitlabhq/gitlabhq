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
    databaseInformation,
  } = el.dataset;

  return new Vue({
    el,
    name: 'DatabaseDiagnosticsView',
    provide: {
      runCollationCheckUrl,
      collationCheckResultsUrl,
      runSchemaCheckUrl,
      schemaCheckResultsUrl,
      databaseInformation: (() => {
        try {
          return JSON.parse(databaseInformation);
        } catch {
          return { databases: {} };
        }
      })(),
    },
    render(createElement) {
      return createElement(CombinedDiagnostics);
    },
  });
};
