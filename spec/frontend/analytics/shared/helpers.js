import { mockDoraMetricsResponseData, mockFlowMetricsResponseData } from './mock_data';

export const mockGraphqlProjectFlowMetricsResponse = (
  mockDataResponse = mockFlowMetricsResponseData,
) =>
  jest.fn().mockResolvedValue({
    data: {
      project: { id: 'fake-flow-metrics-request', flowMetrics: mockDataResponse },
      group: null,
    },
  });

export const mockGraphqlFlowMetricsResponse = (mockDataResponse = mockFlowMetricsResponseData) =>
  jest.fn().mockResolvedValue({
    data: {
      project: null,
      group: { id: 'fake-flow-metrics-request', flowMetrics: mockDataResponse },
    },
  });

export const mockGraphqlDoraMetricsResponse = (mockDataResponse = mockDoraMetricsResponseData) =>
  jest.fn().mockResolvedValue({
    data: {
      project: null,
      group: { id: 'fake-dora-metrics-request', dora: mockDataResponse },
    },
  });
