import dateFormat from 'dateformat';
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
    source_branch_name = null,
    target_branch_name = null,
    author_username = null,
    milestone_title = null,
    assignee_username = [],
    label_name = [],
  } = urlQueryToFilter(url);

  return {
    selectedSourceBranch: source_branch_name,
    selectedTargetBranch: target_branch_name,
    selectedAuthor: author_username,
    selectedMilestone: milestone_title,
    selectedAssigneeList: assignee_username,
    selectedLabelList: label_name,
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
