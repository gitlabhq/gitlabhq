import {
  filterToQueryObject,
  urlQueryToFilter,
  prepareTokens,
  processFilters,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

import {
  PERIOD_FILTER_TOKEN_TYPE,
  SERVICE_NAME_FILTER_TOKEN_TYPE,
  OPERATION_FILTER_TOKEN_TYPE,
  TRACE_ID_FILTER_TOKEN_TYPE,
  DURATION_MS_FILTER_TOKEN_TYPE,
  queryToFilterObj,
  filterObjToQuery,
  filterObjToFilterToken,
  filterTokensToFilterObj,
} from '~/tracing/filters';

jest.mock('~/vue_shared/components/filtered_search_bar/filtered_search_utils');

describe('utils', () => {
  describe('queryToFilterObj', () => {
    it('should build a filter obj', () => {
      const url = 'http://example.com/';
      urlQueryToFilter.mockReturnValue({
        period: '7d',
        service: 'my_service',
        operation: 'my_operation',
        trace_id: 'my_trace_id',
        durationMs: '500',
        [FILTERED_SEARCH_TERM]: 'test',
      });

      const filterObj = queryToFilterObj(url);

      expect(urlQueryToFilter).toHaveBeenCalledWith(url, {
        customOperators: [
          { operator: '>', prefix: 'gt' },
          { operator: '<', prefix: 'lt' },
        ],
        filteredSearchTermKey: 'search',
      });
      expect(filterObj).toEqual({
        period: '7d',
        service: 'my_service',
        operation: 'my_operation',
        traceId: 'my_trace_id',
        durationMs: '500',
        search: 'test',
      });
    });
  });

  describe('filterObjToQuery', () => {
    it('should convert filter object to URL query', () => {
      filterToQueryObject.mockReturnValue('mockquery');

      const query = filterObjToQuery({
        period: '7d',
        serviceName: 'my_service',
        operation: 'my_operation',
        traceId: 'my_trace_id',
        durationMs: '500',
        search: 'test',
      });

      expect(filterToQueryObject).toHaveBeenCalledWith(
        {
          period: '7d',
          service: 'my_service',
          operation: 'my_operation',
          trace_id: 'my_trace_id',
          durationMs: '500',
          'filtered-search-term': 'test',
        },
        {
          customOperators: [
            { applyOnlyToKey: 'durationMs', operator: '>', prefix: 'gt' },
            { applyOnlyToKey: 'durationMs', operator: '<', prefix: 'lt' },
          ],
          filteredSearchTermKey: 'search',
        },
      );
      expect(query).toBe('mockquery');
    });
  });

  describe('filterObjToFilterToken', () => {
    it('should convert filter object to filter tokens', () => {
      const mockTokens = [];
      prepareTokens.mockReturnValue(mockTokens);

      const tokens = filterObjToFilterToken({
        period: '7d',
        serviceName: 'my_service',
        operation: 'my_operation',
        traceId: 'my_trace_id',
        durationMs: '500',
        search: 'test',
      });

      expect(prepareTokens).toHaveBeenCalledWith({
        [PERIOD_FILTER_TOKEN_TYPE]: '7d',
        [SERVICE_NAME_FILTER_TOKEN_TYPE]: 'my_service',
        [OPERATION_FILTER_TOKEN_TYPE]: 'my_operation',
        [TRACE_ID_FILTER_TOKEN_TYPE]: 'my_trace_id',
        [DURATION_MS_FILTER_TOKEN_TYPE]: '500',
        [FILTERED_SEARCH_TERM]: 'test',
      });
      expect(tokens).toBe(mockTokens);
    });
  });

  describe('filterTokensToFilterObj', () => {
    it('should convert filter tokens to filter object', () => {
      const mockTokens = [];
      processFilters.mockReturnValue({
        [SERVICE_NAME_FILTER_TOKEN_TYPE]: 'my_service',
        [PERIOD_FILTER_TOKEN_TYPE]: '7d',
        [OPERATION_FILTER_TOKEN_TYPE]: 'my_operation',
        [TRACE_ID_FILTER_TOKEN_TYPE]: 'my_trace_id',
        [DURATION_MS_FILTER_TOKEN_TYPE]: '500',
        [FILTERED_SEARCH_TERM]: 'test',
      });

      const filterObj = filterTokensToFilterObj(mockTokens);

      expect(processFilters).toHaveBeenCalledWith(mockTokens);
      expect(filterObj).toEqual({
        serviceName: 'my_service',
        period: '7d',
        operation: 'my_operation',
        traceId: 'my_trace_id',
        durationMs: '500',
        search: 'test',
      });
    });
  });
});
