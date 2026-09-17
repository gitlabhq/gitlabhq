import { simpleHash } from '~/lib/utils/text_utility';

export const PREVIEW_PIECE_STAT = 'stat';
export const PREVIEW_PIECE_BAR_ROWS = 'bar-rows';
export const PREVIEW_PIECE_LINE_CHART = 'line-chart';
export const PREVIEW_PIECE_TEXT_LINES = 'text-lines';

export const PREVIEW_PIECE_TYPES = [
  PREVIEW_PIECE_STAT,
  PREVIEW_PIECE_BAR_ROWS,
  PREVIEW_PIECE_LINE_CHART,
  PREVIEW_PIECE_TEXT_LINES,
];

const GRID_COLUMNS = 12;
// A panel spanning at least this many grid columns reads as a full-width block.
const WIDE_PANEL_MIN_WIDTH = 8;
const DEFAULT_MAX_PIECES = 4;
// How many panels (in reading order) to scan for a chart to pull into frame
// when none of the selected pieces is a chart.
const CHART_SCAN_LIMIT = 10;

// Exact visualization `type` strings from
// ee/app/validators/json_schemas/analytics_visualization.json; anything
// unrecognised falls back to text lines.
const VISUALIZATION_PIECE_TYPES = {
  SingleStat: PREVIEW_PIECE_STAT,
  LineChart: PREVIEW_PIECE_LINE_CHART,
  AreaChart: PREVIEW_PIECE_LINE_CHART,
  BarChart: PREVIEW_PIECE_BAR_ROWS,
  ColumnChart: PREVIEW_PIECE_BAR_ROWS,
  StackedColumnChart: PREVIEW_PIECE_BAR_ROWS,
  DataTable: PREVIEW_PIECE_TEXT_LINES,
  AiImpactTable: PREVIEW_PIECE_TEXT_LINES,
};

const GLQL_VISUALIZATION_TYPE = 'Glql';

// Glql visualizations declare their shape as a `display:` line inside the
// query text. A regex is used rather than ~/glql/core/parser, which would
// pull the GLQL compiler into this bundle.
const GLQL_DISPLAY_PIECE_TYPES = {
  stat: PREVIEW_PIECE_STAT,
  barChart: PREVIEW_PIECE_BAR_ROWS,
  columnChart: PREVIEW_PIECE_BAR_ROWS,
  barList: PREVIEW_PIECE_BAR_ROWS,
  divergingBarChart: PREVIEW_PIECE_BAR_ROWS,
  lineChart: PREVIEW_PIECE_LINE_CHART,
  areaChart: PREVIEW_PIECE_LINE_CHART,
};

const glqlDisplay = (visualization) => {
  const glql = visualization?.data?.query?.glql;
  return typeof glql === 'string' ? glql.match(/^\s*display:\s*(\S+)/m)?.[1] : undefined;
};

const pieceTypeFor = (visualization) => {
  if (visualization?.type === GLQL_VISUALIZATION_TYPE) {
    return GLQL_DISPLAY_PIECE_TYPES[glqlDisplay(visualization)] || PREVIEW_PIECE_TEXT_LINES;
  }

  return VISUALIZATION_PIECE_TYPES[visualization?.type] || PREVIEW_PIECE_TEXT_LINES;
};

const toPiece = (panel) => ({
  type: pieceTypeFor(panel.visualization),
  wide: (panel.gridAttributes?.width ?? GRID_COLUMNS) >= WIDE_PANEL_MIN_WIDTH,
});

const byReadingOrder = (a, b) =>
  (a.gridAttributes?.yPos ?? 0) - (b.gridAttributes?.yPos ?? 0) ||
  (a.gridAttributes?.xPos ?? 0) - (b.gridAttributes?.xPos ?? 0);

const isChartPiece = ({ type }) =>
  type === PREVIEW_PIECE_LINE_CHART || type === PREVIEW_PIECE_BAR_ROWS;

// Bump the salt to reshuffle all seeded thumbnails.
const HASH_SALT = 'v1:';

const LEHMER_MODULUS = 2 ** 31 - 1;
const LEHMER_MULTIPLIER = 48271;
const WARMUP_DRAWS = 3;

// Park-Miller "minimal standard" generator: plain arithmetic, so no bitwise
// ops. Early draws track the seed, hence the warm-up.
const seededRng = (key) => {
  const seed = parseInt(simpleHash(`${HASH_SALT}${key}`), 16);
  let state = (seed % (LEHMER_MODULUS - 1)) + 1;
  const next = () => {
    state = (state * LEHMER_MULTIPLIER) % LEHMER_MODULUS;
    return (state - 1) / (LEHMER_MODULUS - 1);
  };
  for (let i = 0; i < WARMUP_DRAWS; i += 1) next();
  return next;
};

const pick = (rng, options) => options[Math.floor(rng() * options.length)];

// One accent per dashboard, from the Pajamas data-viz categorical palette;
// `bar` fills pills/bars, `stroke` colors SVG lines. Key order is the seeded
// pick order, so reordering reshuffles which accent each dashboard gets.
const ACCENTS = {
  blue: { bar: 'gl-bg-data-viz-blue-500', stroke: 'gl-text-data-viz-blue-500' },
  orange: { bar: 'gl-bg-data-viz-orange-500', stroke: 'gl-text-data-viz-orange-500' },
  aqua: { bar: 'gl-bg-data-viz-aqua-500', stroke: 'gl-text-data-viz-aqua-500' },
  green: { bar: 'gl-bg-data-viz-green-500', stroke: 'gl-text-data-viz-green-500' },
  magenta: { bar: 'gl-bg-data-viz-magenta-500', stroke: 'gl-text-data-viz-magenta-500' },
};
const ACCENT_NAMES = Object.keys(ACCENTS);

const STAT_TITLE_WIDTHS = ['gl-w-1/3', 'gl-w-2/5', 'gl-w-1/2'];
const BAR_ROW_WIDTHS = [
  'gl-w-2/5',
  'gl-w-1/2',
  'gl-w-3/5',
  'gl-w-2/3',
  'gl-w-3/4',
  'gl-w-5/6',
  'gl-w-full',
];
const TEXT_LINE_WIDTHS = ['gl-w-1/2', 'gl-w-3/5', 'gl-w-2/3', 'gl-w-3/4', 'gl-w-5/6', 'gl-w-full'];

// Predrawn line-chart curves (viewBox 0 0 100 48); the soft area fill closes
// each curve down to the baseline.
const LINE_CHART_PATHS = [
  'M0,38 C18,34 30,40 46,28 C62,16 76,22 100,8',
  'M0,20 C16,28 28,36 44,32 C62,28 78,12 100,10',
  'M0,28 C14,18 30,14 48,22 C66,30 84,24 100,16',
];

const BAR_ROW_COUNT = 3;
const TEXT_LINE_COUNT = 3;

const PIECE_BUILDERS = {
  [PREVIEW_PIECE_STAT]: (rng) => ({
    type: PREVIEW_PIECE_STAT,
    titleWidth: pick(rng, STAT_TITLE_WIDTHS),
  }),
  [PREVIEW_PIECE_BAR_ROWS]: (rng) => {
    const bars = Array.from({ length: BAR_ROW_COUNT }, () => ({
      width: pick(rng, BAR_ROW_WIDTHS),
      colored: rng() < 0.4,
    }));
    if (!bars.some((bar) => bar.colored)) bars[0].colored = true;
    return { type: PREVIEW_PIECE_BAR_ROWS, bars };
  },
  [PREVIEW_PIECE_LINE_CHART]: (rng) => {
    const linePath = pick(rng, LINE_CHART_PATHS);
    return { type: PREVIEW_PIECE_LINE_CHART, linePath, areaPath: `${linePath} L100,48 L0,48 Z` };
  },
  [PREVIEW_PIECE_TEXT_LINES]: (rng) => ({
    type: PREVIEW_PIECE_TEXT_LINES,
    lines: Array.from({ length: TEXT_LINE_COUNT }, () => pick(rng, TEXT_LINE_WIDTHS)),
  }),
};

const FLEX_SLOT = 'any';
// Piece types a flexible ("any") slot may resolve to.
const FLEX_SLOT_TYPES = [
  PREVIEW_PIECE_BAR_ROWS,
  PREVIEW_PIECE_TEXT_LINES,
  PREVIEW_PIECE_LINE_CHART,
];

// Curated layouts; the seed picks one, `grow` marks the row that fills the
// remaining thumbnail height. Every template stays within the calm caps: at
// most four pieces, three stats, and two rows.
const TEMPLATES = [
  {
    name: 'stats-bars',
    rows: [
      { slots: [PREVIEW_PIECE_STAT, PREVIEW_PIECE_STAT, PREVIEW_PIECE_STAT] },
      { grow: true, slots: [PREVIEW_PIECE_BAR_ROWS] },
    ],
  },
  {
    name: 'stats-text-chart',
    rows: [
      { slots: [PREVIEW_PIECE_STAT, PREVIEW_PIECE_STAT] },
      { grow: true, slots: [PREVIEW_PIECE_TEXT_LINES, PREVIEW_PIECE_LINE_CHART] },
    ],
  },
  {
    name: 'chart-stats',
    rows: [
      { grow: true, slots: [PREVIEW_PIECE_LINE_CHART] },
      { slots: [PREVIEW_PIECE_STAT, PREVIEW_PIECE_STAT, PREVIEW_PIECE_STAT] },
    ],
  },
  {
    name: 'quad',
    rows: [
      { slots: [PREVIEW_PIECE_STAT, PREVIEW_PIECE_STAT] },
      { grow: true, slots: [FLEX_SLOT, FLEX_SLOT] },
    ],
  },
  {
    name: 'stats-bars-text',
    rows: [
      { slots: [PREVIEW_PIECE_STAT, PREVIEW_PIECE_STAT] },
      { grow: true, slots: [PREVIEW_PIECE_BAR_ROWS, PREVIEW_PIECE_TEXT_LINES] },
    ],
  },
];

const MIMIC_TEMPLATE_NAME = 'mimic';
const MIMIC_STAT_ROW_MAX = 3;
// The thumbnail is too short for more rows than this to stay readable, so
// pieces that would need a further row are dropped.
const MIMIC_MAX_ROWS = 2;

// Arranges mimic pieces like the real dashboard reads: the leading run of
// stats forms a tile top row, then wide pieces take a full row while narrow
// ones pair up two per row (a lone narrow piece keeps half the width).
const buildMimicRows = (pieces) => {
  const rows = [];
  let index = 0;

  while (
    index < pieces.length &&
    index < MIMIC_STAT_ROW_MAX &&
    pieces[index].type === PREVIEW_PIECE_STAT
  ) {
    index += 1;
  }
  if (index > 0) {
    rows.push({
      grow: false,
      half: false,
      slots: pieces.slice(0, index).map(({ type }) => type),
    });
  }

  while (index < pieces.length && rows.length < MIMIC_MAX_ROWS) {
    const piece = pieces[index];
    const next = pieces[index + 1];

    if (piece.wide) {
      rows.push({ grow: true, half: false, slots: [piece.type] });
      index += 1;
    } else if (next && !next.wide) {
      rows.push({ grow: true, half: false, slots: [piece.type, next.type] });
      index += 2;
    } else {
      rows.push({ grow: true, half: true, slots: [piece.type] });
      index += 1;
    }
  }

  return rows;
};

// The leading pieces that actually fit the mimic arrangement's row cap;
// buildMimicRows consumes pieces strictly in order, so the rendered set is
// the first N pieces where N is the number of packed slots.
const arrangedPieces = (pieces) => {
  const count = buildMimicRows(pieces).reduce((sum, row) => sum + row.slots.length, 0);
  return pieces.slice(0, count);
};

// A dashboard whose leading panels are all stats and tables would preview as
// chartless even when charts sit just below the fold. Swap the last text-lines
// piece (or, when there is none, the last piece) for the first chart found
// within the scan window so the thumbnail hints at the dashboard's charts.
const withChartBias = (pieces, candidates) => {
  if (pieces.some(isChartPiece)) return pieces;

  const chartPiece = candidates.find(isChartPiece);
  if (!chartPiece) return pieces;

  const lastTextIndex = pieces.map(({ type }) => type).lastIndexOf(PREVIEW_PIECE_TEXT_LINES);
  const swapIndex = lastTextIndex === -1 ? pieces.length - 1 : lastTextIndex;

  const swapped = arrangedPieces(
    pieces.map((piece, index) => (index === swapIndex ? chartPiece : piece)),
  );
  if (swapped.length === pieces.length) return swapped;

  // A wide chart can repack the rows and displace a piece (itself or one that
  // was in frame); keep the outgoing piece's width so every piece still renders.
  return pieces.map((piece, index) =>
    index === swapIndex ? { type: chartPiece.type, wide: piece.wide } : piece,
  );
};

/**
 * Turns a dashboard's persisted config into preview piece descriptors
 * ({ type, wide }) in panel reading order, so the card thumbnail can mimic
 * the dashboard's real composition. Only pieces that fit the thumbnail's
 * two-row arrangement (up to `maxPieces`) are returned, so every returned
 * piece is guaranteed to render. When no chart makes the cut but one exists
 * within the first CHART_SCAN_LIMIT panels, the last text-lines piece (or
 * the last piece) is swapped for that chart so chart-heavy dashboards read
 * as such.
 *
 * @param {Object} config - dashboard config object
 * @param {{ maxPieces?: number }} options
 * @returns {Array<{ type: string, wide: boolean }>|null} null when the config
 *   has no usable panels (the caller then falls back to a seeded thumbnail)
 */
export const configToPreviewPieces = (config, { maxPieces = DEFAULT_MAX_PIECES } = {}) => {
  // Some system dashboards keep `panels: []` and define the real panels on views.
  const panels = config?.panels?.length ? config.panels : config?.views?.[0]?.panels;

  if (!Array.isArray(panels)) {
    return null;
  }

  const sorted = panels
    // Section headings carry no visualization and render no data.
    .filter((panel) => panel?.visualization)
    .sort(byReadingOrder);

  const pieces = arrangedPieces(sorted.slice(0, maxPieces).map(toPiece));

  if (!pieces.length) {
    return null;
  }

  return withChartBias(pieces, sorted.slice(0, CHART_SCAN_LIMIT).map(toPiece));
};

/**
 * Builds the thumbnail wireframe for a dashboard: a PRNG seeded from the
 * dashboard's stable key drives every visual choice, so the same dashboard
 * always renders the same wireframe while different dashboards vary
 * (identicon-style, like default project avatars). When `pieces` (derived
 * from the dashboard's real panels) are given, they replace the seeded
 * template while the seed keeps driving the accent and micro-variation.
 *
 * @param {{ seedKey?: string, pieces?: Array<{ type: string, wide: boolean }> }} options
 * @returns {{ templateName: string, accent: { bar: string, stroke: string },
 *   rows: Array<{ grow: boolean, half: boolean, pieces: Array<Object> }> }}
 */
export const buildThumbnailLayout = ({ seedKey = '', pieces = null } = {}) => {
  const rng = seededRng(seedKey);
  // Always consume the two seeded draws so mimic pieces never change the
  // seeded variation of the wireframe pieces.
  const seededTemplate = pick(rng, TEMPLATES);
  const accentName = pick(rng, ACCENT_NAMES);

  let templateName;
  let rowPlans;
  if (pieces?.length) {
    templateName = MIMIC_TEMPLATE_NAME;
    rowPlans = buildMimicRows(pieces);
  } else {
    templateName = seededTemplate.name;
    rowPlans = seededTemplate.rows.map((row) => ({
      grow: Boolean(row.grow),
      half: false,
      slots: row.slots,
    }));
  }

  const rows = rowPlans.map((row) => ({
    grow: row.grow,
    half: row.half,
    pieces: row.slots.map((slot) => {
      const type = slot === FLEX_SLOT ? pick(rng, FLEX_SLOT_TYPES) : slot;
      return PIECE_BUILDERS[type](rng);
    }),
  }));

  return {
    templateName,
    accent: ACCENTS[accentName],
    rows,
  };
};
