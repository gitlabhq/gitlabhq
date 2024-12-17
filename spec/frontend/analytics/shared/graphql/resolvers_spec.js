import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import * as api from '~/api/analytics_api';
import { resolvers as mockResolvers } from '~/analytics/shared/graphql/resolvers';
import { rawMetricData, mockFlowMetricsCommitsResponseData } from '../mock_data';

describe('~/analytics/shared/graphql/resolvers', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  describe('flowMetricsCommits', () => {
    const mockFullPath = 'fake/namespace/path';
    const mockParams = { startDate: '2024-11-11', endDate: '2024-12-11' };
    const requestParams = {
      fullPath: mockFullPath,
      ...mockParams,
    };

    describe('successful request', () => {
      beforeEach(() => {
        jest.spyOn(api, 'getValueStreamSummaryMetrics').mockResolvedValue({
          data: [...rawMetricData, mockFlowMetricsCommitsResponseData],
        });
      });

      it('will call the getValueStreamSummaryMetrics method', async () => {
        await mockResolvers.Query.flowMetricsCommits(null, requestParams);

        expect(api.getValueStreamSummaryMetrics).toHaveBeenCalled();
      });

      it('will set the request parameters', async () => {
        await mockResolvers.Query.flowMetricsCommits(null, requestParams);

        expect(api.getValueStreamSummaryMetrics).toHaveBeenCalledWith(mockFullPath, {
          created_after: '2024-11-11',
          created_before: '2024-12-11',
        });
      });

      it('will only return the commit data', async () => {
        const resp = await mockResolvers.Query.flowMetricsCommits(null, requestParams);

        expect(resp).toBe(mockFlowMetricsCommitsResponseData);
      });
    });

    describe('with no data', () => {
      beforeEach(() => {
        jest.spyOn(api, 'getValueStreamSummaryMetrics').mockResolvedValue({
          data: [...rawMetricData],
        });
      });

      it('will return undefined', async () => {
        const resp = await mockResolvers.Query.flowMetricsCommits(null, requestParams);

        expect(resp).toBeUndefined();
      });
    });

    describe('with errors', () => {
      const mockError = 'Failed to load';
      beforeEach(() => {
        jest.spyOn(api, 'getValueStreamSummaryMetrics').mockRejectedValue(mockError);
      });

      it('will throw the error', async () => {
        await expect(mockResolvers.Query.flowMetricsCommits(null, requestParams)).rejects.toThrow(
          mockError,
        );
      });
    });
  });
});
