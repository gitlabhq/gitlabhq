import dateFormat from 'dateformat';
import { hideFlash } from '~/flash';
import { slugify } from '~/lib/utils/text_utility';
import { urlQueryToFilter } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { dateFormats } from './constants';

export const filterBySearchTerm = (data = [], searchTerm = '', filterByKey = 'name') => {
  if (!searchTerm?.length) return data;
  return data.filter((item) => item[filterByKey].toLowerCase().includes(searchTerm.toLowerCase()));
};

export const toYmd = (date) => dateFormat(date, dateFormats.isoDate);

/**
 * Takes a url and extracts query parameters used for the shared
 * filter bar
 *
 * @param {string} url The URL to extract query parameters from
 * @returns {Object}
 */
export const extractFilterQueryParameters = (url = '') => {
  const {
    source_branch_name: selectedSourceBranch = null,
    target_branch_name: selectedTargetBranch = null,
    author_username: selectedAuthor = null,
    milestone_title: selectedMilestone = null,
    assignee_username: selectedAssigneeList = [],
    label_name: selectedLabelList = [],
  } = urlQueryToFilter(url);

  return {
    selectedSourceBranch,
    selectedTargetBranch,
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
  };
};

/**
 * Takes a url and extracts sorting and pagination query parameters into an object
 *
 * @param {string} url The URL to extract query parameters from
 * @returns {Object}
 */
export const extractPaginationQueryParameters = (url = '') => {
  const { sort, direction, page } = urlQueryToFilter(url);
  return {
    sort: sort?.value || null,
    direction: direction?.value || null,
    page: page?.value || null,
  };
};

export const getDataZoomOption = ({
  totalItems = 0,
  maxItemsPerPage = 40,
  dataZoom = [{ type: 'slider', bottom: 10, start: 0 }],
}) => {
  if (totalItems <= maxItemsPerPage) {
    return {};
  }

  const intervalEnd = Math.ceil((maxItemsPerPage / totalItems) * 100);

  return dataZoom.map((item) => {
    return {
      ...item,
      end: intervalEnd,
    };
  });
};

export const removeFlash = (type = 'alert') => {
  const flashEl = document.querySelector(`.flash-${type}`);
  if (flashEl) {
    hideFlash(flashEl);
  }
};

/**
 * Prepares metric data to be rendered in the metric_card component
 *
 * @param {MetricData[]} data - The metric data to be rendered
 * @param {Object} popoverContent - Key value pair of data to display in the popover
 * @returns {TransformedMetricData[]} An array of metrics ready to render in the metric_card
 */
export const prepareTimeMetricsData = (data = [], popoverContent = {}) =>
  data.map(({ title: label, identifier, ...rest }) => {
    const metricIdentifier = identifier || slugify(label);
    return {
      ...rest,
      label,
      identifier: metricIdentifier,
      description: popoverContent[metricIdentifier]?.description || '',
    };
  });
