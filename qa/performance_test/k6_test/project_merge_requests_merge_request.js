import http from 'k6/http';
import { check, sleep } from 'k6';

export const TTFB_THRESHOLD = 25;
export const RPS_THRESHOLD = 2;
export const TEST_NAME = 'project_merge_requests_merge_request';
export const LOAD_TEST_VUS = 2;
export const LOAD_TEST_DURATION = '50s';
export const WARMUP_TEST_VUS = 1;
export const WARMUP_TEST_DURATION = '10s';

let API_URL;

export function setup() {
  const baseUrl = __ENV.GITLAB_URL || `http://gitlab.${__ENV.AI_GATEWAY_IP}.nip.io`;
  const token = __ENV.GITLAB_QA_ADMIN_ACCESS_TOKEN || '';
  const projectName = 'Test Seed Project';
  const apiVersion = 'v4';

  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  const searchUrl = `${baseUrl}/api/${apiVersion}/projects?search=${encodeURIComponent(projectName)}`;
  const searchRes = http.get(searchUrl, params);

  let projectId = 1; // Fallback to default
  if (searchRes.status === 200) {
    const projects = JSON.parse(searchRes.body);
    const targetProject = projects.find((project) => project.name === projectName);
    if (targetProject) {
      console.log(`Found project '${projectName}' with ID: ${targetProject.id}`);
      projectId = targetProject.id;
    } else {
      console.warn(
        `Project '${projectName}' not found in search results; falling back to project ID ${projectId}`,
      );
    }
  } else {
    console.error(`Failed to search for projects: ${searchRes.status}`);
  }

  let mrIid = 1; // Fallback to default
  const mrListRes = http.get(
    `${baseUrl}/api/${apiVersion}/projects/${projectId}/merge_requests`,
    params,
  );
  if (mrListRes.status === 200) {
    const mergeRequests = JSON.parse(mrListRes.body);
    if (mergeRequests.length > 0) {
      mrIid = mergeRequests[0].iid;
      console.log(`Found merge request with IID: ${mrIid}`);
    }
  } else {
    console.error(`Failed to list merge requests: ${mrListRes.status}`);
  }

  const apiUrl = `${apiVersion}/projects/${projectId}/merge_requests/${mrIid}`;
  return { apiUrl };
}

export const options = {
  scenarios: {
    warmup: {
      executor: 'constant-vus',
      vus: WARMUP_TEST_VUS,
      duration: WARMUP_TEST_DURATION,
      gracefulStop: '0s',
      tags: { scenario: 'warmup' }, // Tag these requests to filter them out
    },
    load_test: {
      executor: 'constant-vus',
      vus: LOAD_TEST_VUS,
      duration: LOAD_TEST_DURATION,
      startTime: '10s', // Start after warmup completes
      tags: { scenario: 'load_test' },
    },
  },
  thresholds: {
    // Real thresholds that won't fail the test
    'http_req_waiting{scenario:load_test}': [
      { threshold: `p(90)<${TTFB_THRESHOLD}`, abortOnFail: false },
    ],
    'http_reqs{scenario:load_test}': [{ threshold: `rate>=${RPS_THRESHOLD}`, abortOnFail: false }],
  },
};

export default function projectMergeRequestTest(data) {
  const baseUrl = __ENV.GITLAB_URL || `http://gitlab.${__ENV.AI_GATEWAY_IP}.nip.io`;
  const token = __ENV.GITLAB_QA_ADMIN_ACCESS_TOKEN || '';

  API_URL = data.apiUrl;

  const url = `${baseUrl}/api/${API_URL}`;

  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  const res = http.get(url, params);

  let parsedResponse = null;
  try {
    parsedResponse = JSON.parse(res.body);
  } catch (e) {
    parsedResponse = null;
  }

  check(res, {
    'status is 200': () => res.status === 200,
    'response has iid': () => parsedResponse !== null && parsedResponse.iid !== undefined,
  });

  try {
    console.log(
      `Request ${__ITER}: ${res.request.method} ${res.request.url} - MR !${parsedResponse.iid}: "${parsedResponse.title}" - Status ${res.status} - Duration ${res.timings.duration}ms`,
    );
  } catch (e) {
    console.log(
      `Request ${__ITER}: ${res.request.method} ${res.request.url} - Status ${res.status} - Duration ${res.timings.duration}ms - Parse Error`,
    );
  }

  sleep(1);
}
