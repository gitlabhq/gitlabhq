import axios from '~/lib/utils/axios_utils';
// import mockData from './mock_traces.json';

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

function traceWithDuration(trace) {
  // aggregating duration on the client for now, but expecting to be coming from the backend
  // https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2274
  const duration = trace.spans[0].duration_nano;
  return {
    ...trace,
    duration: duration / 1000,
  };
}

async function fetchTrace(tracingUrl, traceId) {
  if (!traceId) {
    throw new Error('traceId is required.');
  }

  const { data } = await axios.get(tracingUrl, {
    withCredentials: true,
    params: {
      trace_id: traceId,
    },
  });

  // TODO: Improve local GDK dev experience with tracing https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2308
  // const data = mockData;
  // const trace = data.traces.find((t) => t.trace_id === traceId);

  if (!Array.isArray(data.traces) || data.traces.length === 0) {
    throw new Error('traces are missing/invalid in the response.'); // eslint-disable-line @gitlab/require-i18n-strings
  }

  const trace = data.traces[0];
  return traceWithDuration(trace);
}

/**
 * Filters (and operators) allowed by tracing query API
 */
const SUPPORTED_FILTERS = {
  durationMs: ['>', '<'],
  operation: ['=', '!='],
  serviceName: ['=', '!='],
  period: ['='],
  traceId: ['=', '!='],
  // free-text 'search' temporarily ignored https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2309
};

/**
 * Mapping of filter name to query param
 */
const FILTER_TO_QUERY_PARAM = {
  durationMs: 'duration_nano',
  operation: 'operation',
  serviceName: 'service_name',
  period: 'period',
  traceId: 'trace_id',
};

const FILTER_OPERATORS_PREFIX = {
  '!=': 'not',
  '>': 'gt',
  '<': 'lt',
};

/**
 * Builds the query param name for the given filter and operator
 *
 * @param {String} filterName - The filter name
 * @param {String} operator - The operator
 * @returns String | undefined - Query param name
 */
function getFilterParamName(filterName, operator) {
  const paramKey = FILTER_TO_QUERY_PARAM[filterName];
  if (!paramKey) return undefined;

  if (operator === '=') {
    return paramKey;
  }

  const prefix = FILTER_OPERATORS_PREFIX[operator];
  if (prefix) {
    return `${prefix}[${paramKey}]`;
  }

  return undefined;
}

/**
 * Builds URLSearchParams from a filter object of type { [filterName]: undefined | null | Array<{operator: String, value: any} }
 *  e.g:
 *
 *  filterObj =  {
 *      durationMs: [{operator: '>', value: '100'}, {operator: '<', value: '1000' }],
 *      operation: [{operator: '=', value: 'someOp' }],
 *      serviceName: [{operator: '!=', value: 'foo' }]
 *    }
 *
 * It handles converting the filter to the proper supported query params
 *
 * @param {Object} filterObj : An Object representing filters
 * @returns URLSearchParams
 */
function filterObjToQueryParams(filterObj) {
  const filterParams = new URLSearchParams();

  Object.keys(SUPPORTED_FILTERS).forEach((filterName) => {
    const filterValues = filterObj[filterName] || [];
    const supportedFilters = filterValues.filter((f) =>
      SUPPORTED_FILTERS[filterName].includes(f.operator),
    );
    supportedFilters.forEach(({ operator, value: rawValue }) => {
      const paramName = getFilterParamName(filterName, operator);

      let value = rawValue;
      if (filterName === 'durationMs') {
        // converting durationMs to duration_nano
        value *= 1000;
      }

      if (paramName && value) {
        filterParams.append(paramName, value);
      }
    });
  });
  return filterParams;
}

/**
 * Fetches traces with given tracing API URL and filters
 *
 * @param {String} tracingUrl : The API base URL
 * @param {Object} filters : A filter object of type: { [filterName]: undefined | null | Array<{operator: String, value: String} }
 *  e.g:
 *
 *    {
 *      durationMs: [ {operator: '>', value: '100'}, {operator: '<', value: '1000'}],
 *      operation: [ {operator: '=', value: 'someOp}],
 *      serviceName: [ {operator: '!=', value: 'foo}]
 *    }
 *
 * @returns Array<Trace> : A list of traces
 */
async function fetchTraces(tracingUrl, filters = {}) {
  const filterParams = filterObjToQueryParams(filters);

  const { data } = await axios.get(tracingUrl, {
    withCredentials: true,
    params: filterParams,
  });
  // TODO: Improve local GDK dev experience with tracing https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2308
  // Uncomment the line below to test this locally
  // const data = mockData;

  if (!Array.isArray(data.traces)) {
    throw new Error('traces are missing/invalid in the response.'); // eslint-disable-line @gitlab/require-i18n-strings
  }
  return data.traces.map(traceWithDuration);
}

export function buildClient({ provisioningUrl, tracingUrl }) {
  return {
    enableTraces: () => enableTraces(provisioningUrl),
    isTracingEnabled: () => isTracingEnabled(provisioningUrl),
    fetchTraces: (filters) => fetchTraces(tracingUrl, filters),
    fetchTrace: (traceId) => fetchTrace(tracingUrl, traceId),
  };
}
