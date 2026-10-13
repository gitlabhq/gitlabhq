import { clamp } from 'lodash-es';
import {
  defaultHeight as DEFAULT_CHART_HEIGHT_PX,
  grid as GL_GRID,
} from '@gitlab/ui/src/utils/charts/config';
import {
  GL_COLOR_DATA_BLUE_50,
  GL_COLOR_DATA_BLUE_100,
  GL_COLOR_DATA_BLUE_200,
  GL_COLOR_DATA_BLUE_300,
  GL_COLOR_DATA_BLUE_400,
  GL_COLOR_DATA_BLUE_500,
  GL_COLOR_DATA_BLUE_600,
  GL_COLOR_DATA_BLUE_700,
  GL_COLOR_DATA_BLUE_800,
  GL_COLOR_DATA_BLUE_900,
} from '@gitlab/ui/src/tokens/build/js/tokens';
import { formatCount, formatRate } from '../../../utils/value_format';

const AVG_CHAR_WIDTH_PX = 7; // ~glyph width of the 12px axis-label font
const MIN_LABEL_WIDTH_PX = 7 * AVG_CHAR_WIDTH_PX; // GlBarChart's stock 7-char allowance
const MAX_LABEL_WIDTH_PX = 160; // past this, ECharts ellipsizes by pixel width
// Share labels such as "Returning · 1,555 · 78%" get a wider cap so they
// render in full; plain labels keep the narrower one.
const SHARE_LABEL_MAX_WIDTH_PX = 240;
const NAME_GAP_PADDING_PX = 16;
const AXIS_TITLE_SPACE_PX = 20;

// GlBarChart's grid bottom (GL_GRID.bottom) holds the x-axis tick labels and
// its title; this is the part the tick labels need when the title is hidden.
const X_AXIS_LABELS_SPACE_PX = 28;
const ROW_HEIGHT_PX = 48; // one category band with one bar; GlBarChart's bars fill half of it

export const COLOR_BY_SERIES = 'series';
export const COLOR_BY_CATEGORY = 'category';
export const COLOR_BY_OPTIONS = [COLOR_BY_SERIES, COLOR_BY_CATEGORY];
// displayConfig.categoryLabels: 'plain' (default) or 'valueAndShare'.
export const CATEGORY_LABELS_VALUE_AND_SHARE = 'valueAndShare';

// Most prominent shade first. The data tokens are the same hexes in both
// colour modes, so one ramp cannot clear the 3:1 contrast minimum for
// graphical objects on both backgrounds; each mode gets its own.
export const CATEGORY_SHADES_LIGHT = [
  GL_COLOR_DATA_BLUE_900,
  GL_COLOR_DATA_BLUE_800,
  GL_COLOR_DATA_BLUE_700,
  GL_COLOR_DATA_BLUE_600,
  GL_COLOR_DATA_BLUE_500,
];
export const CATEGORY_SHADES_DARK = [
  GL_COLOR_DATA_BLUE_50,
  GL_COLOR_DATA_BLUE_100,
  GL_COLOR_DATA_BLUE_200,
  GL_COLOR_DATA_BLUE_300,
  GL_COLOR_DATA_BLUE_400,
];

/**
 * Picks the solid shade for the category at `position` of `count`, spreading
 * the categories evenly across the scale so two categories get its two ends.
 * More categories than shades cycle through the scale.
 *
 * @param {number} position - the category's position on the scale, 0 being
 *   the most prominent
 * @param {number} count - the number of categories
 * @param {string[]} shades - the scale to pick from, most prominent first
 * @returns {string} a hex colour
 */
export const categoryShadeFor = (position, count, shades) => {
  const last = shades.length - 1;
  if (count > shades.length) return shades[position % shades.length];
  if (count <= 1) return shades[0];
  return shades[Math.round((position * last) / (count - 1))];
};

/**
 * Height in pixels for a horizontal bar chart with `rowCount` categories.
 * GlChart otherwise renders at its default height whatever the row count,
 * which stretches a two-row chart into slabs and overflows a dashboard panel
 * body, which then scrolls. Capped at that default, so charts with many rows
 * render as before.
 *
 * @param {number} rowCount - the number of categories
 * @param {object} [options]
 * @param {boolean} [options.axisTitle] - whether the value axis has a title
 *   to leave room for; defaults to true
 * @param {number} [options.barsPerRow] - how many bars share a category band,
 *   which is the metric count for tiled series; defaults to 1
 * @returns {number}
 */
export const barChartHeightFor = (rowCount, { axisTitle = true, barsPerRow = 1 } = {}) => {
  const bottom = axisTitle ? GL_GRID.bottom : X_AXIS_LABELS_SPACE_PX;
  const rows = Math.max(rowCount, 1);
  // Each extra tiled bar adds half a band, so bars stay about as thick as a
  // single one rather than being squeezed into the same 48px.
  const rowHeight = (ROW_HEIGHT_PX * (Math.max(barsPerRow, 1) + 1)) / 2;
  return Math.min(rows * rowHeight + GL_GRID.top + bottom, DEFAULT_CHART_HEIGHT_PX);
};

/**
 * Gives every point of a GlBarChart data set its own solid colour, so each
 * category gets a distinct bar. GlBarChart colours a whole series at once, so
 * the colour goes on the points themselves, border included, or its series
 * border and the tooltip swatch would keep the palette colour. ECharts draws
 * row 0 at the bottom, so positions count from the top to give the top row
 * the most prominent shade.
 *
 * @param {Object<string, Array>} seriesData - GlBarChart `data`, keyed by
 *   series name, with `[value, category]` tuples
 * @param {string[]} shades - the scale to pick from, most prominent first
 * @returns {Object<string, Array>} the same shape with styled points
 */
export const colorSeriesByCategory = (seriesData, shades) =>
  Object.fromEntries(
    Object.entries(seriesData).map(([name, points]) => [
      name,
      points.map((value, index) => {
        const color = categoryShadeFor(points.length - 1 - index, points.length, shades);
        const itemStyle = { color, borderColor: color };
        return { value, itemStyle, emphasis: { itemStyle } };
      }),
    ]),
  );

/**
 * Builds a category axis label formatter that appends each category's value
 * and its share of the total, e.g. "Returning · 1,555 · 78%". The total is the
 * sum of the points given, so shares always add up to 100% of the rows shown.
 *
 * @param {Array<[number, string]>} points - one series' `[value, category]`
 *   tuples, as built by buildBarSeriesData
 * @param {object} [options]
 * @param {function(string): string} [options.formatLabel] - maps raw category
 *   values to display labels; defaults to String
 * @param {function(number): string} [options.formatValue] - formats the
 *   category's value; defaults to the count formatter
 * @returns {function(string): string}
 */
export const shareLabelFormatter = (
  points,
  { formatLabel = String, formatValue = formatCount } = {},
) => {
  const valueByCategory = new Map(points.map(([value, category]) => [category, value]));
  const total = points.reduce((sum, [value]) => sum + value, 0);

  return (category) => {
    const value = valueByCategory.get(category) ?? 0;
    const share = formatRate(total ? value / total : 0);
    return `${formatLabel(category)} · ${formatValue(value)} · ${share}`;
  };
};

/**
 * Builds GlBarChart `option` overrides that size the category (y) axis to fit
 * the actual labels. GlBarChart's defaults assume 7-character labels: they
 * truncate anything longer and reserve a fixed 64px gutter shared by the
 * labels and the axis title, which mangles longer labels such as dates
 * ("2026..." instead of "Jan 1, 2026") and cramps the title.
 *
 * Returns only `yAxis` and `grid` keys so callers can spread the result
 * alongside their own `xAxis` options. Relies on GlBarChart deep-merging the
 * consumer `option` prop over its defaults, so these keys win.
 *
 * @param {string[]} categoryLabels - the formatted category axis labels
 * @param {object} [options]
 * @param {function(string): string} [options.formatter] - maps raw category
 *   values to display labels; defaults to identity for pre-formatted data
 * @param {boolean} [options.axisTitle] - whether the axes have titles to
 *   leave room for; defaults to true
 * @param {boolean} [options.shareLabels] - whether the labels carry a value
 *   and share suffix, which get a wider gutter cap; defaults to false
 * @returns {{ yAxis: object, grid: object }}
 */
export const barCategoryAxisOptions = (
  categoryLabels,
  { formatter = (label) => label, axisTitle = true, shareLabels = false } = {},
) => {
  const longest = categoryLabels.reduce((max, label) => Math.max(max, label.length), 0);
  const maxLabelWidth = shareLabels ? SHARE_LABEL_MAX_WIDTH_PX : MAX_LABEL_WIDTH_PX;
  const labelWidth = clamp(longest * AVG_CHAR_WIDTH_PX, MIN_LABEL_WIDTH_PX, maxLabelWidth);
  const nameGap = labelWidth + NAME_GAP_PADDING_PX;

  return {
    yAxis: {
      nameGap,
      axisLabel: {
        // Replaces GlBarChart's truncating default formatter; overly long
        // labels are instead ellipsized by ECharts at `width` pixels.
        formatter,
        width: labelWidth,
        overflow: 'truncate',
      },
    },
    grid: {
      left: nameGap + (axisTitle ? AXIS_TITLE_SPACE_PX : 0),
      ...(axisTitle ? {} : { bottom: X_AXIS_LABELS_SPACE_PX }),
    },
  };
};
