/**
 * Imports an analytics dashboard datasource (FOSS).
 *
 * EE adds licensed data sources via the matching `ee/...` file. Consumers
 * should resolve this module through the `ee_else_ce` webpack alias so the
 * EE override is picked up automatically in EE builds.
 */

export default {
  glql: () => import('./glql'),
  merge_requests: () => import('./merge_requests'),
  merge_request_counts: () => import('./merge_request_counts'),
  mean_time_to_merge: () => import('./mean_time_to_merge'),
};
