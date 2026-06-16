/**
 * Registers FOSS-resolvable visualizations.
 *
 * EE adds licensed visualizations via the matching `ee/...` file, which
 * spreads this registry into its own. Consumers should resolve this module
 * through the `ee_else_ce` webpack alias so the EE override is picked up
 * automatically in EE builds.
 */

export default {
  AreaChart: () => import('./area_chart.vue'),
  DataTable: () => import('./data_table/data_table.vue'),
  LineChart: () => import('./line_chart.vue'),
  SingleStat: () => import('./single_stat.vue'),
};
