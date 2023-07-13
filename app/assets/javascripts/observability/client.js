// import axios from '~/lib/utils/axios_utils';
import * as mockData from './mock_traces.json';

function enableTraces(provisioningUrl) {
  console.log(`Enabling tracing - ${provisioningUrl}`); // eslint-disable-line no-console

  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, 500);
  });
}

function isTracingEnabled(provisioningUrl) {
  console.log(`Checking status - ${provisioningUrl}`); // eslint-disable-line no-console

  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(false);
    }, 1000);
  });
}

function fetchTraces(tracingUrl) {
  console.log(`Fetching traces from ${tracingUrl}`); // eslint-disable-line no-console

  // axios.get(`${this.endpoint}/v1/jaeger/22/api/services`, { credentials: 'include' });
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(mockData.data);
    }, 2000);
  });
}

export function buildClient({ provisioningUrl, tracingUrl }) {
  return {
    enableTraces: () => enableTraces(provisioningUrl),
    isTracingEnabled: () => isTracingEnabled(provisioningUrl),
    fetchTraces: () => fetchTraces(tracingUrl),
  };
}
