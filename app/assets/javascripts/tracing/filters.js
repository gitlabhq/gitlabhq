import {
  filterToQueryObject,
  urlQueryToFilter,
  prepareTokens,
  processFilters,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

export const PERIOD_FILTER_TOKEN_TYPE = 'period';
export const SERVICE_NAME_FILTER_TOKEN_TYPE = 'service-name';
export const OPERATION_FILTER_TOKEN_TYPE = 'operation';
export const TRACE_ID_FILTER_TOKEN_TYPE = 'trace-id';
export const DURATION_MS_FILTER_TOKEN_TYPE = 'duration-ms';

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
    period = null,
    service = null,
    operation = null,
    trace_id: traceId = null,
    durationMs = null,
  } = filter;
  const search = filter[FILTERED_SEARCH_TERM];
  return {
    period,
    service,
    operation,
    traceId,
    durationMs,
    search,
  };
}

export function filterObjToQuery(filters) {
  return filterToQueryObject(
    {
      period: filters.period,
      service: filters.serviceName,
      operation: filters.operation,
      trace_id: filters.traceId,
      durationMs: filters.durationMs,
      [FILTERED_SEARCH_TERM]: filters.search,
    },
    {
      filteredSearchTermKey: 'search',
      customOperators: [
        {
          operator: '>',
          prefix: 'gt',
          applyOnlyToKey: 'durationMs',
        },
        {
          operator: '<',
          prefix: 'lt',
          applyOnlyToKey: 'durationMs',
        },
      ],
    },
  );
}

export function filterObjToFilterToken(filters) {
  return prepareTokens({
    [PERIOD_FILTER_TOKEN_TYPE]: filters.period,
    [SERVICE_NAME_FILTER_TOKEN_TYPE]: filters.serviceName,
    [OPERATION_FILTER_TOKEN_TYPE]: filters.operation,
    [TRACE_ID_FILTER_TOKEN_TYPE]: filters.traceId,
    [DURATION_MS_FILTER_TOKEN_TYPE]: filters.durationMs,
    [FILTERED_SEARCH_TERM]: filters.search,
  });
}

export function filterTokensToFilterObj(tokens) {
  const {
    [SERVICE_NAME_FILTER_TOKEN_TYPE]: serviceName,
    [PERIOD_FILTER_TOKEN_TYPE]: period,
    [OPERATION_FILTER_TOKEN_TYPE]: operation,
    [TRACE_ID_FILTER_TOKEN_TYPE]: traceId,
    [DURATION_MS_FILTER_TOKEN_TYPE]: durationMs,
    [FILTERED_SEARCH_TERM]: search,
  } = processFilters(tokens);

  return {
    serviceName,
    period,
    operation,
    traceId,
    durationMs,
    search,
  };
}
