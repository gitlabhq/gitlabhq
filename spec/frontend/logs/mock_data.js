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
  { timestamp: '2019-12-13T13:43:18.2760123Z', message: 'Log 1' },
  { timestamp: '2019-12-13T13:43:18.2760123Z', message: 'Log 2' },
  { timestamp: '2019-12-13T13:43:26.8420123Z', message: 'Log 3' },
];

export const mockTrace = [
  'Dec 13 13:43:18.276Z | Log 1',
  'Dec 13 13:43:18.276Z | Log 2',
  'Dec 13 13:43:26.842Z | Log 3',
];

export const mockResponse = {
  pod_name: mockPodName,
  pods: mockPods,
  logs: mockLogsResult,
  cursor: mockNextCursor,
};

export const mockSearch = 'foo +bar';
