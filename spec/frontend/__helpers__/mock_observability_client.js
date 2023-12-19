import { buildClient } from '~/observability/client';

export function createMockClient() {
  const mockClient = buildClient({
    provisioningUrl: 'provisioning-url',
    tracingUrl: 'tracing-url',
    servicesUrl: 'services-url',
    operationsUrl: 'operations-url',
    metricsUrl: 'metrics-url',
    metricsSearchUrl: 'metrics-search-url',
  });

  Object.getOwnPropertyNames(mockClient)
    .filter((item) => typeof mockClient[item] === 'function')
    .forEach((item) => {
      mockClient[item] = jest.fn();
    });

  return mockClient;
}
