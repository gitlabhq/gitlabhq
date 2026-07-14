const baseEntryPoints = {
  default: ['./main'],
  sentry: './sentry/index.js',
  coverage_persistence: './entrypoints/coverage_persistence.js',
  performance_bar: './entrypoints/performance_bar.js',
  jira_connect_app: './jira_connect/subscriptions/index.js',
  sandboxed_mermaid_v11: './lib/mermaid_v11.js',
  redirect_listbox: './entrypoints/behaviors/redirect_listbox.js',
  sandboxed_swagger: './lib/swagger.js',
  super_sidebar: './entrypoints/super_sidebar.js',
  tracker: './entrypoints/tracker.js',
  graphql_explorer: './entrypoints/graphql_explorer.js',
};

module.exports = { baseEntryPoints };
