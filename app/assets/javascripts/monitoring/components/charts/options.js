import { isFinite, uniq, sortBy, includes } from 'lodash';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import { __, s__ } from '~/locale';
import { formatDate, timezones, formats } from '../../format_date';
import { thresholdModeTypes } from '../../constants';

const yAxisBoundaryGap = [0.1, 0.1];
/**
 * Max string length of formatted axis tick
 */
const maxDataAxisTickLength = 8;
//  Defaults
const defaultFormat = SUPPORTED_FORMATS.engineering;

const defaultYAxisFormat = defaultFormat;
const defaultYAxisPrecision = 2;

const defaultTooltipFormat = defaultFormat;
const defaultTooltipPrecision = 3;

// Give enough space for y-axis with units and name.
const chartGridLeft = 63; // larger gap than gitlab-ui's default to fit formatted numbers
const chartGridRight = 10; // half of the scroll-handle icon for data zoom
const yAxisNameGap = chartGridLeft - 12; // offset the axis label line-height

// Axis options

/**
 * Axis types
 * @see https://echarts.apache.org/en/option.html#xAxis.type
 */
export const axisTypes = {
  /**
   * Category axis, suitable for discrete category data.
   */
  category: 'category',
  /**
   *  Time axis, suitable for continuous time series data.
   */
  time: 'time',
};

/**
 * Converts .yml parameters to echarts axis options for data axis
 * @param {Object} param - Dashboard .yml definition options
 */
const getDataAxisOptions = ({ format, precision, name }) => {
  const formatter = getFormatter(format); // default to engineeringNotation, same as gitlab-ui
  return {
    name,
    nameLocation: 'center', // same as gitlab-ui's default
    scale: true,
    axisLabel: {
      formatter: val => formatter(val, precision, maxDataAxisTickLength),
    },
  };
};

/**
 * Converts .yml parameters to echarts y-axis options
 * @param {Object} param - Dashboard .yml definition options
 */
export const getYAxisOptions = ({
  name = s__('Metrics|Values'),
  format = defaultYAxisFormat,
  precision = defaultYAxisPrecision,
} = {}) => {
  return {
    nameGap: yAxisNameGap,
    scale: true,
    boundaryGap: yAxisBoundaryGap,

    ...getDataAxisOptions({
      name,
      format,
      precision,
    }),
  };
};

export const getTimeAxisOptions = ({
  timezone = timezones.LOCAL,
  format = formats.shortDateTime,
} = {}) => ({
  name: __('Time'),
  type: axisTypes.time,
  axisLabel: {
    formatter: date => formatDate(date, { format, timezone }),
  },
  axisPointer: {
    snap: false,
  },
});

// Chart grid

/**
 * Grid with enough room to display chart.
 */
export const getChartGrid = ({ left = chartGridLeft, right = chartGridRight } = {}) => ({
  left,
  right,
});

// Tooltip options

export const getTooltipFormatter = ({
  format = defaultTooltipFormat,
  precision = defaultTooltipPrecision,
} = {}) => {
  const formatter = getFormatter(format);
  return num => formatter(num, precision);
};

// Thresholds

/**
 *
 * Used to find valid thresholds for the gauge chart
 *
 * An array of thresholds values is
 * - duplicate values are removed;
 * - filtered for invalid values;
 * - sorted in ascending order;
 * - only first two values are used.
 */
export const getValidThresholds = ({ mode, range = {}, values = [] } = {}) => {
  const supportedModes = [thresholdModeTypes.ABSOLUTE, thresholdModeTypes.PERCENTAGE];
  const { min, max } = range;

  /**
   * return early if min and max have invalid values
   * or mode has invalid value
   */
  if (!isFinite(min) || !isFinite(max) || min >= max || !includes(supportedModes, mode)) {
    return [];
  }

  const uniqueThresholds = uniq(values);

  const numberThresholds = uniqueThresholds.filter(threshold => isFinite(threshold));

  const validThresholds = numberThresholds.filter(threshold => {
    let isValid;

    if (mode === thresholdModeTypes.PERCENTAGE) {
      isValid = threshold > 0 && threshold < 100;
    } else if (mode === thresholdModeTypes.ABSOLUTE) {
      isValid = threshold > min && threshold < max;
    }

    return isValid;
  });

  const transformedThresholds = validThresholds.map(threshold => {
    let transformedThreshold;

    if (mode === 'percentage') {
      transformedThreshold = (threshold / 100) * (max - min);
    } else {
      transformedThreshold = threshold;
    }

    return transformedThreshold;
  });

  const sortedThresholds = sortBy(transformedThresholds);

  const reducedThresholdsArray =
    sortedThresholds.length > 2
      ? [sortedThresholds[0], sortedThresholds[1]]
      : [...sortedThresholds];

  return reducedThresholdsArray;
};
