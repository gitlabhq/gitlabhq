import dateFormat from 'dateformat';
import { unescape } from 'lodash';
import { dateFormats } from '~/analytics/shared/constants';
import { hideFlash } from '~/flash';
import { sanitize } from '~/lib/dompurify';
import { roundToNearestHalf } from '~/lib/utils/common_utils';
import { getDateInPast } from '~/lib/utils/datetime/date_calculation_utility';
import { parseSeconds } from '~/lib/utils/datetime_utility';
import { slugify } from '~/lib/utils/text_utility';
import { s__, sprintf } from '../locale';

export const removeFlash = (type = 'alert') => {
  const flashEl = document.querySelector(`.flash-${type}`);
  if (flashEl) {
    hideFlash(flashEl);
  }
};

/**
 * Takes the stages and median data, combined with the selected stage, to build an
 * array which is formatted to proivde the data required for the path navigation.
 *
 * @param {Array} stages - The stages available to the group / project
 * @param {Object} medians - The median values for the stages available to the group / project
 * @param {Object} stageCounts - The total item count for the stages available
 * @param {Object} selectedStage - The currently selected stage
 * @returns {Array} An array of stages formatted with data required for the path navigation
 */
export const transformStagesForPathNavigation = ({
  stages,
  medians,
  stageCounts = {},
  selectedStage,
}) => {
  const formattedStages = stages.map((stage) => {
    return {
      metric: medians[stage?.id],
      selected: stage?.id === selectedStage?.id, // Also could null === null cause an issue here?
      stageCount: stageCounts && stageCounts[stage?.id],
      icon: null,
      ...stage,
    };
  });

  return formattedStages;
};

export const timeSummaryForPathNavigation = ({ seconds, hours, days, minutes, weeks, months }) => {
  if (months) {
    return sprintf(s__('ValueStreamAnalytics|%{value}M'), {
      value: roundToNearestHalf(months),
    });
  } else if (weeks) {
    return sprintf(s__('ValueStreamAnalytics|%{value}w'), {
      value: roundToNearestHalf(weeks),
    });
  } else if (days) {
    return sprintf(s__('ValueStreamAnalytics|%{value}d'), {
      value: roundToNearestHalf(days),
    });
  } else if (hours) {
    return sprintf(s__('ValueStreamAnalytics|%{value}h'), { value: hours });
  } else if (minutes) {
    return sprintf(s__('ValueStreamAnalytics|%{value}m'), { value: minutes });
  } else if (seconds) {
    return unescape(sanitize(s__('ValueStreamAnalytics|&lt;1m'), { ALLOWED_TAGS: [] }));
  }
  return '-';
};

/**
 * Takes a raw median value in seconds and converts it to a string representation
 * ie. converts 172800 => 2d (2 days)
 *
 * @param {Number} Median - The number of seconds for the median calculation
 * @returns {String} String representation ie 2w
 */
export const medianTimeToParsedSeconds = (value) =>
  timeSummaryForPathNavigation({
    ...parseSeconds(value, { daysPerWeek: 7, hoursPerDay: 24 }),
    seconds: value,
  });

/**
 * Takes the raw median value arrays and converts them into a useful object
 * containing the string for display in the path navigation
 * ie. converts [{ id: 'test', value: 172800 }] => { 'test': '2d' }
 *
 * @param {Array} Medians - Array of stage median objects, each contains a `id`, `value` and `error`
 * @returns {Object} Returns key value pair with the stage name and its display median value
 */
export const formatMedianValues = (medians = []) =>
  medians.reduce((acc, { id, value = 0 }) => {
    return {
      ...acc,
      [id]: value ? medianTimeToParsedSeconds(value) : '-',
    };
  }, {});

export const filterStagesByHiddenStatus = (stages = [], isHidden = true) =>
  stages.filter(({ hidden = false }) => hidden === isHidden);

const toIsoFormat = (d) => dateFormat(d, dateFormats.isoDate);

/**
 * Takes an integer specifying the number of days to subtract
 * from the date specified will return the 2 dates, formatted as ISO dates
 *
 * @param {Number} daysInPast - Number of days in the past to subtract
 * @param {Date} [today=new Date] - Date to subtract days from, defaults to today
 * @returns {Object} Returns 'now' and the 'past' date formatted as ISO dates
 */
export const calculateFormattedDayInPast = (daysInPast, today = new Date()) => {
  return {
    now: toIsoFormat(today),
    past: toIsoFormat(getDateInPast(today, daysInPast)),
  };
};

/**
 * @typedef {Object} MetricData
 * @property {String} title - Title of the metric measured
 * @property {String} value - String representing the decimal point value, e.g '1.5'
 * @property {String} [unit] - String representing the decimal point value, e.g '1.5'
 *
 * @typedef {Object} TransformedMetricData
 * @property {String} label - Title of the metric measured
 * @property {String} value - String representing the decimal point value, e.g '1.5'
 * @property {String} key - Slugified string based on the 'title'
 * @property {String} description - String to display for a description
 * @property {String} unit - String representing the decimal point value, e.g '1.5'
 */

/**
 * Prepares metric data to be rendered in the metric_card component
 *
 * @param {MetricData[]} data - The metric data to be rendered
 * @param {Object} popoverContent - Key value pair of data to display in the popover
 * @returns {TransformedMetricData[]} An array of metrics ready to render in the metric_card
 */

export const prepareTimeMetricsData = (data = [], popoverContent = {}) =>
  data.map(({ title: label, ...rest }) => {
    const key = slugify(label);
    return {
      ...rest,
      label,
      key,
      description: popoverContent[key]?.description || '',
    };
  });
