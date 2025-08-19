import http from 'k6/http';
import { check, sleep } from 'k6';

export const TTFB_THRESHOLD = 25;
export const RPS_THRESHOLD = 2;
export const TEST_NAME = 'group_merge_requests';
export const LOAD_TEST_VUS = 2;
export const LOAD_TEST_DURATION = '50s';
export const WARMUP_TEST_VUS = 1;
export const WARMUP_TEST_DURATION = '10s';

// Global variable to store the group ID
let groupId;

export function setup() {
  const baseUrl = __ENV.GITLAB_URL || `http://gitlab.${__ENV.AI_GATEWAY_IP}.nip.io`;
  const token = __ENV.GITLAB_QA_ADMIN_ACCESS_TOKEN || '';
  const groupName = 'Test Seed Group';

  // Search for the group by name
  const searchUrl = `${baseUrl}/api/v4/groups?search=${encodeURIComponent(groupName)}`;
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  const res = http.get(searchUrl, params);

  if (res.status === 200) {
    const groups = JSON.parse(res.body);
    const targetGroup = groups.find((group) => group.name === groupName);

    if (targetGroup) {
      console.log(`Found group '${groupName}' with ID: ${targetGroup.id}`);
      return { groupId: targetGroup.id };
    }
    console.error(`Group '${groupName}' not found`);
    return { groupId: '5' }; // Fallback to default
  }
  console.error(`Failed to search for groups: ${res.status}`);
  return { groupId: '5' }; // Fallback to default
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

export default function groupMergeRequestsTest(data) {
  const baseUrl = __ENV.GITLAB_URL || `http://gitlab.${__ENV.AI_GATEWAY_IP}.nip.io`;
  const apiVersion = 'v4';
  groupId = __ENV.GROUP_ID || data.groupId;
  const token = __ENV.GITLAB_QA_ADMIN_ACCESS_TOKEN || '';

  const url = `${baseUrl}/api/${apiVersion}/groups/${groupId}/merge_requests`;

  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };

  const res = http.get(url, params);
  const parsedResponse = JSON.parse(res.body);

  check(res, {
    'status is 200': () => res.status === 200,
    'response is array': () => {
      try {
        return Array.isArray(parsedResponse);
      } catch (e) {
        return false;
      }
    },
    'response has merge requests': () => {
      try {
        return Array.isArray(parsedResponse) && parsedResponse.length > 0;
      } catch (e) {
        return false;
      }
    },
  });

  try {
    if (parsedResponse.length > 0) {
      const mr = parsedResponse[0];
      console.log(
        `Request ${__ITER}: ${res.request.method} ${res.request.url} - MR !${mr.iid}: "${mr.title} - Status ${res.status} - Duration ${res.timings.duration}ms "`,
      );
    } else {
      console.log(
        `Request ${__ITER}: ${res.request.method} ${res.request.url} - Status ${res.status} - Duration ${res.timings.duration}ms - No MRs found`,
      );
    }
  } catch (e) {
    console.log(
      `Request ${__ITER}: ${res.request.method} ${res.request.url} - Status ${res.status} - Duration ${res.timings.duration}ms - Parse Error`,
    );
  }

  sleep(1);
}
