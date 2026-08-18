import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  return initVueApp({
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
    component: CombinedDiagnostics,
  });
};
