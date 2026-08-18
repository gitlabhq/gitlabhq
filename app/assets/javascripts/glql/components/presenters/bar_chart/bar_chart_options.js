import { clamp } from 'lodash-es';

const AVG_CHAR_WIDTH_PX = 7; // ~glyph width of the 12px axis-label font
const MIN_LABEL_WIDTH_PX = 7 * AVG_CHAR_WIDTH_PX; // GlBarChart's stock 7-char allowance
const MAX_LABEL_WIDTH_PX = 160; // past this, ECharts ellipsizes by pixel width
const NAME_GAP_PADDING_PX = 16;
const AXIS_TITLE_SPACE_PX = 20;

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
 * @returns {{ yAxis: object, grid: object }}
 */
export const barCategoryAxisOptions = (categoryLabels, { formatter = (label) => label } = {}) => {
  const longest = categoryLabels.reduce((max, label) => Math.max(max, label.length), 0);
  const labelWidth = clamp(longest * AVG_CHAR_WIDTH_PX, MIN_LABEL_WIDTH_PX, MAX_LABEL_WIDTH_PX);
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
    grid: { left: nameGap + AXIS_TITLE_SPACE_PX },
  };
};
