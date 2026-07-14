/**
 * Intercept GraphQL operation names to build a single
 * list of all missing operations for better visibility
 * while writing new test suites that require new handlers.
 */
export const missingOperations = new Set([]);

/**
 * Capture a graphql operation that failed
 * @param {string} name - name of the graphql operation
 */
export function captureMissingOperation(name) {
  missingOperations.add(name);
}

/**
 * Clear the missing operations set.
 */
export function clearMissingOperations() {
  missingOperations.clear();
}

/**
 * Request tracking utilities for MSW integration tests.
 * Allows tests to verify which endpoints were called and with what parameters.
 */

export const capturedRequests = {};

/**
 * Resets all captured requests. Now included in the global test setup teardown phase.
 */
export function resetCapturedRequests() {
  Object.keys(capturedRequests).forEach((key) => delete capturedRequests[key]);
}

/**
 * Captures a request for later verification in tests.
 * @param {string} name - The operation/endpoint name
 * @param {Request} request - The MSW request object
 */
export function captureRequest(name, request) {
  if (!capturedRequests[name]) {
    capturedRequests[name] = [];
  }

  capturedRequests[name].push({
    url: request.url.toString(),
    params: Object.fromEntries(request.url.searchParams),
    method: request.method,
    timestamp: Date.now(),
  });
}

/**
 * Returns GraphQL operations that fired since the baselineRequests snapshot.
 *
 * @param {Object} baselineRequests - Snapshot from snapshotRequests() before the action
 * @param {Object} allRequests - Snapshot from snapshotRequests() after the action
 * @returns {Object} Map of operationName -> count of NEW calls
 * @example
 *   const baselineRequests = snapshotRequests();
 *   // ... perform action ...
 *   const newCalls = getSnapshotRequestsDiff(baselineRequests, snapshotRequests());
 *   // newCalls = { workItemUpdate: 1 }
 */
function getSnapshotRequestsDiff(baselineRequests, allRequests) {
  return Object.keys(allRequests).reduce((acc, operationName) => {
    const baseCount = baselineRequests[operationName] || 0;
    const currentCount = allRequests[operationName] || 0;
    const delta = currentCount - baseCount;

    if (delta > 0) {
      acc[operationName] = delta;
    }

    return acc;
  }, {});
}
/**
 * Accepts a list of expected and forbidden operations and throws if any expectations are violated.
 * @param {String} op - The operation name to check
 * @param {Array<string|RegExp>} forbiddenOperations - List of operations or patterns that are not allowed
 * @returns {boolean} True if the operation is forbidden, false otherwise
 */
function isForbiddenOperation(op, forbiddenOperations) {
  return forbiddenOperations.some((pattern) => {
    if (pattern instanceof RegExp) {
      return pattern.test(op);
    }
    return op === pattern;
  });
}

/**
 * Captures current GraphQL request counts by operation name.
 * Use this before an action to establish calls that already occurred
 * and then compare against it after the action to see what new operations fired.
 *
 * @returns {Object} Map of operationName -> count
 * @example
 *   const baselineRequests = snapshotRequests();
 *   // baselineRequests = { getWorkItemsFullEE: 1, projectLabels: 1 }
 */
export function snapshotRequests() {
  return Object.keys(capturedRequests).reduce((acc, operationName) => {
    acc[operationName] = capturedRequests[operationName].length;
    return acc;
  }, {});
}

/**
 * Asserts that expected operations fired AND forbidden operations did NOT fire.
 * Use this to verify cache integrity - ensure mutations work without triggering refetches.
 *
 * @param {Object} baselineRequests - Snapshot from snapshotRequests()
 * @param {Object} assertions - What to expect and forbid
 * @param {Array<string>} assertions.expect - Operations that MUST fire (e.g., the mutation)
 * @param {Array<string|RegExp>} assertions.forbid - Operations that must NOT fire (e.g., list refetches)
 * @throws {Error} If expected operations didn't fire or forbidden operations did fire
 * @example
 *   const baselineRequests = snapshotRequests();
 *   clickUpdateButton();
 *   await waitFor(() => {
 *     expectGraphQLCalls(baselineRequests, {
 *       expect: ['workItemUpdate'],
 *       forbid: ['getWorkItemsFullEE', 'projectLabels'],
 *     });
 *   });
 */
export function expectGraphQLCalls(
  baselineRequests,
  { expect: expectedOperations, forbid: forbiddenOperations },
) {
  const newCalls = getSnapshotRequestsDiff(baselineRequests, snapshotRequests());
  const actualOperations = Object.keys(newCalls);

  // First, check that expected operations actually fired
  const missing = expectedOperations.filter((op) => !actualOperations.includes(op));
  if (missing.length > 0) {
    throw new Error(
      `Expected operations did not fire: [${missing.join(', ')}]\n` +
        `All operations that fired: [${actualOperations.join(', ')}]`,
    );
  }

  // Then, check if any forbidden operations fired (cache misses)
  const violated = actualOperations.filter((op) => isForbiddenOperation(op, forbiddenOperations));

  if (violated.length > 0) {
    // Build a counts map of everything that fired, and the same map with the
    // forbidden operations removed (what we expected to fire). Comparing them
    // with a Jest matcher renders a readable red/green diff that highlights the
    // unexpected calls, instead of dumping the full config and call list.
    const actualCalls = { ...newCalls };
    const expectedCalls = Object.fromEntries(
      Object.entries(newCalls).filter(([op]) => !isForbiddenOperation(op, forbiddenOperations)),
    );

    const headline =
      `Unexpected GraphQL call (possible cache miss).\n` +
      `These operations should have been served from the cache: [${violated.join(', ')}]`;

    try {
      expect(actualCalls).toEqual(expectedCalls);
    } catch (error) {
      error.message = `${headline}\n\n${error.message}`;
      throw error;
    }
  }
}
