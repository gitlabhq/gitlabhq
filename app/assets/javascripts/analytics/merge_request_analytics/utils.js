import { __ } from '~/locale';
import dateFormat from '~/lib/dateformat';
import { getMonthNames, secondsToDays } from '~/lib/utils/datetime_utility';
import {
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_SOURCE_BRANCH,
  TOKEN_TYPE_TARGET_BRANCH,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { filterToQueryObject } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { dateFormats } from '../shared/constants';

/**
 * A utility function which accepts a date range and returns
 * computed month data which is required to build the GraphQL
 * query for the Throughput Analytics chart
 *
 * @param {Date} startDate the startDate for the data range
 * @param {Date} endDate the endDate for the data range
 * @param {String} format the date format to be used
 *
 * @return {Array} the computed month data
 */
export const computeMonthRangeData = (startDate, endDate, format = dateFormats.isoDate) => {
  const monthData = [];
  const monthNames = getMonthNames(true);

  for (
    let dateCursor = new Date(endDate);
    dateCursor >= startDate;
    dateCursor.setMonth(dateCursor.getMonth(), 0)
  ) {
    const monthIndex = dateCursor.getMonth();
    const year = dateCursor.getFullYear();

    const mergedAfter = new Date(year, monthIndex, 1);
    const mergedBefore = new Date(year, monthIndex + 1, 1);

    monthData.unshift({
      year,
      month: monthNames[monthIndex],
      mergedAfter: dateFormat(mergedAfter, format),
      mergedBefore: dateFormat(mergedBefore, format),
    });
  }

  if (monthData.length) {
    monthData[0].mergedAfter = dateFormat(startDate, format); // Set first item to startDate
    monthData[monthData.length - 1].mergedBefore = dateFormat(endDate, format); // Set last item to endDate
  }

  return monthData;
};

/**
 * A utility function which accepts the raw throughput chart data
 * and transforms it into the format required for the area chart.
 *
 * @param {Object} chartData the raw chart data
 *
 * @return {Array} the formatted chart data
 */
export const formatThroughputChartData = (chartData) => {
  if (!chartData) return [];
  const data = Object.keys(chartData)
    .filter((key) => key.toLowerCase() !== '__typename')
    .map((key) => [key.split('_').join(' '), chartData[key].count]); // key: Aug_2020 => Aug 2020

  return [
    {
      name: __('Merge Requests merged'),
      data,
    },
  ];
};

/**
 * A utility function which accepts the raw throughput data
 * and computes the mean time to merge.
 *
 * @param {Object} rawData the raw throughput data
 *
 * @return {Object} the computed MTTM data
 */
export const computeMttmData = (rawData) => {
  if (!rawData) return {};

  const mttmData = Object.values(rawData)
    // eslint-disable-next-line @gitlab/require-i18n-strings
    .filter((value) => value !== 'Project')
    .reduce(
      (total, monthData) => {
        return {
          count: total.count + monthData.count,
          totalTimeToMerge: total.totalTimeToMerge + monthData.totalTimeToMerge,
        };
      },
      {
        count: 0,
        totalTimeToMerge: 0,
      },
    );

  const value =
    mttmData.totalTimeToMerge && mttmData.count
      ? secondsToDays(mttmData.totalTimeToMerge / mttmData.count)
      : '-';
  return {
    title: __('Mean time to merge'),
    unit: __('days'),
    value,
  };
};

/**
 * Takes a filter object and converts it into an MR throughput query object
 *
 * @param {Object} filters
 * @returns {Object} query object with filters for MR throughput GraphQL query
 */
export const filterToMRThroughputQueryObject = (filters = {}) => {
  const {
    [TOKEN_TYPE_LABEL]: labels,
    [`not[${TOKEN_TYPE_LABEL}]`]: notLabels,
    [TOKEN_TYPE_SOURCE_BRANCH]: sourceBranches,
    [TOKEN_TYPE_TARGET_BRANCH]: targetBranches,
    [TOKEN_TYPE_MILESTONE]: milestoneTitle,
    [`not[${TOKEN_TYPE_MILESTONE}]`]: notMilestoneTitle,
    [TOKEN_TYPE_ASSIGNEE]: assigneeUsername,
    [TOKEN_TYPE_AUTHOR]: authorUsername,
  } = filterToQueryObject(filters);

  return {
    labels,
    notLabels,
    sourceBranches,
    targetBranches,
    milestoneTitle: milestoneTitle?.at(0),
    notMilestoneTitle: notMilestoneTitle?.at(0),
    assigneeUsername: assigneeUsername?.at(0),
    authorUsername: authorUsername?.at(0),
  };
};
