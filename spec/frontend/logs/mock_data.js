export const mockProjectPath = 'root/autodevops-deploy';
export const mockEnvName = 'production';
export const mockEnvironmentsEndpoint = `${mockProjectPath}/environments.json`;
export const mockEnvId = '99';
export const mockDocumentationPath = '/documentation.md';

const makeMockEnvironment = (id, name, advancedQuerying) => ({
  id,
  project_path: mockProjectPath,
  name,
  logs_api_path: '/dummy_logs_path.json',
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
    message: '10.36.0.1 - - [16/Oct/2019:06:29:48 UTC] "GET / HTTP/1.1" 200 13',
  },
  { timestamp: '2019-12-13T13:43:18.2760123Z', message: '- -> /' },
  {
    timestamp: '2019-12-13T13:43:26.8420123Z',
    message: '10.36.0.1 - - [16/Oct/2019:06:29:57 UTC] "GET / HTTP/1.1" 200 13',
  },
  { timestamp: '2019-12-13T13:43:26.8420123Z', message: '- -> /' },
  {
    timestamp: '2019-12-13T13:43:28.3710123Z',
    message: '10.36.0.1 - - [16/Oct/2019:06:29:58 UTC] "GET / HTTP/1.1" 200 13',
  },
  { timestamp: '2019-12-13T13:43:28.3710123Z', message: '- -> /' },
  {
    timestamp: '2019-12-13T13:43:36.8860123Z',
    message: '10.36.0.1 - - [16/Oct/2019:06:30:07 UTC] "GET / HTTP/1.1" 200 13',
  },
  { timestamp: '2019-12-13T13:43:36.8860123Z', message: '- -> /' },
  {
    timestamp: '2019-12-13T13:43:38.4000123Z',
    message: '10.36.0.1 - - [16/Oct/2019:06:30:08 UTC] "GET / HTTP/1.1" 200 13',
  },
  { timestamp: '2019-12-13T13:43:38.4000123Z', message: '- -> /' },
  {
    timestamp: '2019-12-13T13:43:46.8420123Z',
    message: '10.36.0.1 - - [16/Oct/2019:06:30:17 UTC] "GET / HTTP/1.1" 200 13',
  },
  { timestamp: '2019-12-13T13:43:46.8430123Z', message: '- -> /' },
  {
    timestamp: '2019-12-13T13:43:48.3240123Z',
    message: '10.36.0.1 - - [16/Oct/2019:06:30:18 UTC] "GET / HTTP/1.1" 200 13',
  },
  { timestamp: '2019-12-13T13:43:48.3250123Z', message: '- -> /' },
];

export const mockTrace = [
  'Dec 13 13:43:18.276Z | 10.36.0.1 - - [16/Oct/2019:06:29:48 UTC] "GET / HTTP/1.1" 200 13',
  'Dec 13 13:43:18.276Z | - -> /',
  'Dec 13 13:43:26.842Z | 10.36.0.1 - - [16/Oct/2019:06:29:57 UTC] "GET / HTTP/1.1" 200 13',
  'Dec 13 13:43:26.842Z | - -> /',
  'Dec 13 13:43:28.371Z | 10.36.0.1 - - [16/Oct/2019:06:29:58 UTC] "GET / HTTP/1.1" 200 13',
  'Dec 13 13:43:28.371Z | - -> /',
  'Dec 13 13:43:36.886Z | 10.36.0.1 - - [16/Oct/2019:06:30:07 UTC] "GET / HTTP/1.1" 200 13',
  'Dec 13 13:43:36.886Z | - -> /',
  'Dec 13 13:43:38.400Z | 10.36.0.1 - - [16/Oct/2019:06:30:08 UTC] "GET / HTTP/1.1" 200 13',
  'Dec 13 13:43:38.400Z | - -> /',
  'Dec 13 13:43:46.842Z | 10.36.0.1 - - [16/Oct/2019:06:30:17 UTC] "GET / HTTP/1.1" 200 13',
  'Dec 13 13:43:46.843Z | - -> /',
  'Dec 13 13:43:48.324Z | 10.36.0.1 - - [16/Oct/2019:06:30:18 UTC] "GET / HTTP/1.1" 200 13',
  'Dec 13 13:43:48.325Z | - -> /',
];

export const mockSearch = 'foo +bar';
