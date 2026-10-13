const IS_EE = require('./is_ee_env');

const baseEntryPoints = {
  default: ['./main'],
  sentry: './sentry/index.js',
  coverage_persistence: './entrypoints/coverage_persistence.js',
  performance_bar: './entrypoints/performance_bar.js',
  jira_connect_app: './jira_connect/subscriptions/index.js',
  sandboxed_mermaid_v11: './lib/mermaid_v11.js',
  sandboxed_mermaid_v12: './lib/mermaid_v12.js',
  redirect_listbox: './entrypoints/behaviors/redirect_listbox.js',
  sandboxed_swagger: './lib/swagger.js',
  super_sidebar: './entrypoints/super_sidebar.js',
  tracker: './entrypoints/tracker.js',
  graphql_explorer: './entrypoints/graphql_explorer.js',
  duo_panel: './entrypoints/duo_panel.js',
};

const ALWAYS_LOADED_ENTRY_POINTS = ['super_sidebar', 'tracker', 'sentry', 'performance_bar'];

// The entry exists in FOSS too, as a no-op, so its vue3_migration.yml
// resolves. Only the EE layout loads it.
if (IS_EE) {
  ALWAYS_LOADED_ENTRY_POINTS.push('duo_panel');
}

/**
 * Entry name of a page entry, from its `index.js` path relative to a JS root:
 * `pages/projects/jobs/show/index.js` -> `pages.projects.jobs.show`.
 */
const pageEntryName = (indexPath) => indexPath.replace(/\/index\.js$/, '').replace(/\//g, '.');

module.exports = { baseEntryPoints, ALWAYS_LOADED_ENTRY_POINTS, pageEntryName };
