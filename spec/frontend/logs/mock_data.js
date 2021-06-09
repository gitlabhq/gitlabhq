const mockProjectPath = 'root/autodevops-deploy';

export const mockEnvName = 'production';
export const mockEnvironmentsEndpoint = `${mockProjectPath}/environments.json`;
export const mockEnvId = '99';
export const mockDocumentationPath = '/documentation.md';
export const mockLogsEndpoint = '/dummy_logs_path.json';
export const mockCursor = 'MOCK_CURSOR';
export const mockNextCursor = 'MOCK_NEXT_CURSOR';

const makeMockEnvironment = (id, name, advancedQuerying) => ({
  id,
  project_path: mockProjectPath,
  name,
  logs_api_path: mockLogsEndpoint,
  enable_advanced_logs_querying: advancedQuerying,
});

export const mockEnvironment = makeMockEnvironment(mockEnvId, mockEnvName, true);
export const mockEnvironments = [
  mockEnvironment,
  makeMockEnvironment(101, 'staging', false),
  makeMockEnvironment(102, 'review/a-feature', false),
];

export const mockPodName = 'production-764c58d697-aaaaa';
export const mockPods = [
  mockPodName,
  'production-764c58d697-bbbbb',
  'production-764c58d697-ccccc',
  'production-764c58d697-ddddd',
];

export const mockLogsResult = [
  {
    timestamp: '2019-12-13T13:43:18.2760123Z',
    message: 'log line 1',
    pod: 'foo',
  },
  {
    timestamp: '2019-12-13T13:43:18.2760123Z',
    message: 'log line A',
    pod: 'bar',
  },
  {
    timestamp: '2019-12-13T13:43:26.8420123Z',
    message: 'log line 2',
    pod: 'foo',
  },
  {
    timestamp: '2019-12-13T13:43:26.8420123Z',
    message: 'log line B',
    pod: 'bar',
  },
];

export const mockTrace = [
  'Dec 13 13:43:18.276 | foo | log line 1',
  'Dec 13 13:43:18.276 | bar | log line A',
  'Dec 13 13:43:26.842 | foo | log line 2',
  'Dec 13 13:43:26.842 | bar | log line B',
];

export const mockResponse = {
  pod_name: mockPodName,
  pods: mockPods,
  logs: mockLogsResult,
  cursor: mockNextCursor,
};

export const mockSearch = 'foo +bar';
