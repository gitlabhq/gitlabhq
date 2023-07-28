import axios from '~/lib/utils/axios_utils';
import mockData from './mock_traces.json';

function enableTraces() {
  // TODO remove mocks https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2271
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, 1000);
  });
}

function isTracingEnabled() {
  // TODO remove mocks https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2271
  return new Promise((resolve) => {
    setTimeout(() => {
      // Currently relying on manual provisioning, hence assuming tracing is enabled
      resolve(true);
    }, 1000);
  });
}

async function fetchTrace(tracingUrl, traceId) {
  const data = mockData;
  const trace = data.traces.find((t) => t.trace_id === traceId);
  const duration = trace.spans.reduce((acc, cur) => acc + cur.duration_nano, 0);
  return {
    ...trace,
    duration: duration / 1000,
  };
}

async function fetchTraces(tracingUrl) {
  const { data } = await axios.get(tracingUrl, { withCredentials: true });
  if (!Array.isArray(data.traces)) {
    throw new Error('traces are missing/invalid in the response.'); // eslint-disable-line @gitlab/require-i18n-strings
  }
  return data.traces.map((t) => {
    // aggregating duration on the client for now, but expecting to be coming from the backend
    const duration = t.spans.reduce((acc, cur) => acc + cur.duration_nano, 0);
    return {
      ...t,
      duration: duration / 1000,
    };
  });
}

export function buildClient({ provisioningUrl, tracingUrl }) {
  return {
    enableTraces: () => enableTraces(provisioningUrl),
    isTracingEnabled: () => isTracingEnabled(provisioningUrl),
    fetchTraces: () => fetchTraces(tracingUrl),
    fetchTrace: (traceId) => fetchTrace(tracingUrl, traceId),
  };
}
