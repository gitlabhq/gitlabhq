export const DEFAULT_PAGE_SIZE = 20;

export const DISPLAY_TYPES = {
  LIST: 'list',
  ORDERED_LIST: 'orderedList',
  TABLE: 'table',
  STAT: 'stat',
  COLUMN_CHART: 'columnChart',
  LINE_CHART: 'lineChart',
  BAR_CHART: 'barChart',
};

// Display types that opt into the page-size default and the load-more UI.
// Anything not in this set renders without pagination — appropriate for
// aggregated views (charts) where paginating the underlying buckets would
// produce a partial picture. An explicit `limit:` in the GLQL block is
// always honored; non-paginated types simply skip the default page size.
export const PAGINATED_DISPLAY_TYPES_WITH_DEFAULT_LIMIT = new Set([
  DISPLAY_TYPES.LIST,
  DISPLAY_TYPES.ORDERED_LIST,
  DISPLAY_TYPES.TABLE,
]);

export const DEFAULT_DISPLAY_TYPE = DISPLAY_TYPES.LIST;
export const MODE_STANDARD = 'standard';
export const MODE_ANALYTICS = 'analytics';
export const FIELD_TYPES = {
  ATTRIBUTE: 'attribute',
  DIMENSION: 'dimension',
  METRIC: 'metric',
};

// list/table render edge-to-edge (they own their row/cell spacing); every other
// display is a self-contained block that needs an outer inset from its container.
export const FULL_BLEED_DISPLAY_TYPES = new Set([
  DISPLAY_TYPES.LIST,
  DISPLAY_TYPES.ORDERED_LIST,
  DISPLAY_TYPES.TABLE,
]);
