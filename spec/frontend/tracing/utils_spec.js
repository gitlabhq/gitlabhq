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
} from '~/tracing/constants';

import {
  queryToFilterObj,
  filterObjToQuery,
  filterObjToFilterToken,
  filterTokensToFilterObj,
} from '~/tracing/utils';

jest.mock('~/vue_shared/components/filtered_search_bar/filtered_search_utils');

describe('utils', () => {
  describe('queryToFilterObj', () => {
    it('should build a filter obj', () => {
      const url = 'http://example.com/';
      urlQueryToFilter.mockReturnValue({
        time_range: 'last_7_days',
        service: 'my_service',
        operation: 'my_operation',
        trace_id: 'my_trace_id',
        duration: '500',
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
        timeRange: 'last_7_days',
        service: 'my_service',
        operation: 'my_operation',
        traceId: 'my_trace_id',
        duration: '500',
        search: 'test',
      });
    });
  });

  describe('filterObjToQuery', () => {
    it('should convert filter object to URL query', () => {
      filterToQueryObject.mockReturnValue('mockquery');

      const query = filterObjToQuery({
        timeRange: 'last_7_days',
        serviceName: 'my_service',
        operation: 'my_operation',
        traceId: 'my_trace_id',
        duration: '500',
        search: 'test',
      });

      expect(filterToQueryObject).toHaveBeenCalledWith(
        {
          time_range: 'last_7_days',
          service: 'my_service',
          operation: 'my_operation',
          trace_id: 'my_trace_id',
          duration: '500',
          'filtered-search-term': 'test',
        },
        {
          customOperators: [
            { applyOnlyToKey: 'duration', operator: '>', prefix: 'gt' },
            { applyOnlyToKey: 'duration', operator: '<', prefix: 'lt' },
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
        timeRange: 'last_7_days',
        serviceName: 'my_service',
        operation: 'my_operation',
        traceId: 'my_trace_id',
        duration: '500',
        search: 'test',
      });

      expect(prepareTokens).toHaveBeenCalledWith({
        [TIME_RANGE_FILTER_TOKEN_TYPE]: 'last_7_days',
        [SERVICE_NAME_FILTER_TOKEN_TYPE]: 'my_service',
        [OPERATION_FILTER_TOKEN_TYPE]: 'my_operation',
        [TRACE_ID_FILTER_TOKEN_TYPE]: 'my_trace_id',
        [DURATION_FILTER_TOKEN_TYPE]: '500',
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
        [TIME_RANGE_FILTER_TOKEN_TYPE]: 'last_7_days',
        [OPERATION_FILTER_TOKEN_TYPE]: 'my_operation',
        [TRACE_ID_FILTER_TOKEN_TYPE]: 'my_trace_id',
        [DURATION_FILTER_TOKEN_TYPE]: '500',
        [FILTERED_SEARCH_TERM]: 'test',
      });

      const filterObj = filterTokensToFilterObj(mockTokens);

      expect(processFilters).toHaveBeenCalledWith(mockTokens);
      expect(filterObj).toEqual({
        serviceName: 'my_service',
        timeRange: 'last_7_days',
        operation: 'my_operation',
        traceId: 'my_trace_id',
        duration: '500',
        search: 'test',
      });
    });
  });
});
