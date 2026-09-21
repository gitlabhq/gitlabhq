export const DEFAULT_PAGE_SIZE = 20;

export const DISPLAY_TYPES = {
  LIST: 'list',
  ORDERED_LIST: 'orderedList',
  TABLE: 'table',
  STAT: 'stat',
  COLUMN_CHART: 'columnChart',
  LINE_CHART: 'lineChart',
  BAR_CHART: 'barChart',
  BAR_LIST: 'barList',
  AREA_CHART: 'areaChart',
  HEAT_MAP: 'heatMap',
  DIVERGING_BAR_CHART: 'divergingBarChart',
};

// Shows one page and offers Load more for the rest. An explicit `limit:` sets the page size,
// otherwise DEFAULT_PAGE_SIZE applies.
export const PAGINATION_LOAD_MORE = 'load-more';

// Fetches page after page before rendering, up to MAX_AUTO_PAGINATED_ROWS, because a partial
// set of aggregated rows draws a complete-looking but wrong picture. With an explicit `limit:`
// a single page of that size is fetched instead, with no way to load more.
export const PAGINATION_AUTO = 'auto';

// Every display type names its strategy, so a new one has to pick rather than inherit.
export const PAGINATION_BY_DISPLAY_TYPE = {
  [DISPLAY_TYPES.LIST]: PAGINATION_LOAD_MORE,
  [DISPLAY_TYPES.ORDERED_LIST]: PAGINATION_LOAD_MORE,
  [DISPLAY_TYPES.TABLE]: PAGINATION_LOAD_MORE,
  [DISPLAY_TYPES.STAT]: PAGINATION_AUTO,
  [DISPLAY_TYPES.COLUMN_CHART]: PAGINATION_AUTO,
  [DISPLAY_TYPES.LINE_CHART]: PAGINATION_AUTO,
  [DISPLAY_TYPES.BAR_CHART]: PAGINATION_AUTO,
  [DISPLAY_TYPES.BAR_LIST]: PAGINATION_AUTO,
  [DISPLAY_TYPES.AREA_CHART]: PAGINATION_AUTO,
  [DISPLAY_TYPES.HEAT_MAP]: PAGINATION_AUTO,
  [DISPLAY_TYPES.DIVERGING_BAR_CHART]: PAGINATION_AUTO,
};

export const AGGREGATED_AUTO_PAGE_SIZE = 100;
export const MAX_AUTO_PAGINATED_ROWS = 1000;

// "Copy contents" copies these displays from their rendered DOM, which already carries
// the on-screen order and formatting.
export const DOM_COPY_DISPLAY_TYPES = new Set([
  DISPLAY_TYPES.LIST,
  DISPLAY_TYPES.ORDERED_LIST,
  DISPLAY_TYPES.TABLE,
  DISPLAY_TYPES.STAT,
]);

// "Copy contents" builds a table from the query result for these displays, since ECharts
// renders to SVG/canvas with nothing copyable in the DOM.
export const DATA_COPY_DISPLAY_TYPES = new Set([
  DISPLAY_TYPES.COLUMN_CHART,
  DISPLAY_TYPES.LINE_CHART,
  DISPLAY_TYPES.BAR_CHART,
  DISPLAY_TYPES.BAR_LIST,
  DISPLAY_TYPES.AREA_CHART,
  DISPLAY_TYPES.HEAT_MAP,
  DISPLAY_TYPES.DIVERGING_BAR_CHART,
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
