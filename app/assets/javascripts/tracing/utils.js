import {
  filterToQueryObject,
  urlQueryToFilter,
  prepareTokens,
  processFilters,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  TIME_RANGE_FILTER_TOKEN_TYPE,
  SERVICE_NAME_FILTER_TOKEN_TYPE,
  OPERATION_FILTER_TOKEN_TYPE,
  TRACE_ID_FILTER_TOKEN_TYPE,
  DURATION_FILTER_TOKEN_TYPE,
} from './constants';

export function queryToFilterObj(url) {
  const filter = urlQueryToFilter(url, {
    filteredSearchTermKey: 'search',
    customOperators: [
      {
        operator: '>',
        prefix: 'gt',
      },
      {
        operator: '<',
        prefix: 'lt',
      },
    ],
  });
  const {
    time_range: timeRange = null,
    service = null,
    operation = null,
    trace_id: traceId = null,
    duration = null,
  } = filter;
  const search = filter[FILTERED_SEARCH_TERM];
  return {
    timeRange,
    service,
    operation,
    traceId,
    duration,
    search,
  };
}

export function filterObjToQuery(filters) {
  return filterToQueryObject(
    {
      time_range: filters.timeRange,
      service: filters.serviceName,
      operation: filters.operation,
      trace_id: filters.traceId,
      duration: filters.duration,
      [FILTERED_SEARCH_TERM]: filters.search,
    },
    {
      filteredSearchTermKey: 'search',
      customOperators: [
        {
          operator: '>',
          prefix: 'gt',
          applyOnlyToKey: 'duration',
        },
        {
          operator: '<',
          prefix: 'lt',
          applyOnlyToKey: 'duration',
        },
      ],
    },
  );
}

export function filterObjToFilterToken(filters) {
  return prepareTokens({
    [TIME_RANGE_FILTER_TOKEN_TYPE]: filters.timeRange,
    [SERVICE_NAME_FILTER_TOKEN_TYPE]: filters.serviceName,
    [OPERATION_FILTER_TOKEN_TYPE]: filters.operation,
    [TRACE_ID_FILTER_TOKEN_TYPE]: filters.traceId,
    [DURATION_FILTER_TOKEN_TYPE]: filters.duration,
    [FILTERED_SEARCH_TERM]: filters.search,
  });
}

export function filterTokensToFilterObj(tokens) {
  const {
    [SERVICE_NAME_FILTER_TOKEN_TYPE]: serviceName,
    [TIME_RANGE_FILTER_TOKEN_TYPE]: timeRange,
    [OPERATION_FILTER_TOKEN_TYPE]: operation,
    [TRACE_ID_FILTER_TOKEN_TYPE]: traceId,
    [DURATION_FILTER_TOKEN_TYPE]: duration,
    [FILTERED_SEARCH_TERM]: search,
  } = processFilters(tokens);

  return {
    serviceName,
    timeRange,
    operation,
    traceId,
    duration,
    search,
  };
}
