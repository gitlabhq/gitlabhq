import { HTTP_STATUS_FORBIDDEN, HTTP_STATUS_SERVICE_UNAVAILABLE } from '~/lib/utils/http_status';

export const GLQL_ERROR_NO_ACCESS = 'no_access';
export const GLQL_ERROR_UNAVAILABLE = 'unavailable';
export const GLQL_ERROR_NOT_CONFIGURED = 'not_configured';
export const GLQL_ERROR_TIMEOUT = 'timeout';
export const GLQL_ERROR_RATE_LIMITED = 'rate_limited';
export const GLQL_ERROR_INVALID_QUERY = 'invalid_query';
export const GLQL_ERROR_GENERIC = 'generic';

// Stable codes the backend attaches via GraphQL error extensions:
// Analytics::RequiresSiphonReplication and BaseAggregationFieldResolver.
const CATEGORY_BY_CODE = {
  AGGREGATION_NOT_AUTHORIZED: GLQL_ERROR_NO_ACCESS,
  SIPHON_REPLICATION_DISABLED: GLQL_ERROR_UNAVAILABLE,
  CLICKHOUSE_NOT_CONFIGURED: GLQL_ERROR_NOT_CONFIGURED,
};

// Backends predating the extension codes emit only the message.
const NOT_AUTHORIZED_MESSAGE = /is not authorized/;

// Thrown by our own code or a WASM panic, not by a query mistake: keep reporting these.
const RUNTIME_ERRORS = [
  TypeError,
  ReferenceError,
  RangeError,
  globalThis.WebAssembly?.RuntimeError,
];

const isRuntimeError = (error) => RUNTIME_ERRORS.some((type) => type && error instanceof type);

// `/api/glql` returns 403 both for rate limiting (Analytics::Glql::QueryService's
// GlqlQueryLockedError) and for real authorization failures inherited from
// GraphqlController; only the response body tells them apart.
const RATE_LIMIT_MESSAGE = /temporarily blocked/i;

const isRateLimited = (networkError) =>
  (networkError?.result?.errors || []).some(({ message }) =>
    RATE_LIMIT_MESSAGE.test(message || ''),
  );

/**
 * Maps a GLQL query failure to a category describing why it failed.
 *
 * @param {Error|ApolloError} error - the rejection from a GLQL execution; both
 *   ApolloErrors (with networkError/graphQLErrors) and single GraphQL errors work.
 * @returns {string} one of the GLQL_ERROR_* categories
 */
export const classifyGlqlError = (error) => {
  if (!error) return GLQL_ERROR_GENERIC;

  switch (error.networkError?.statusCode) {
    case HTTP_STATUS_FORBIDDEN:
      return isRateLimited(error.networkError) ? GLQL_ERROR_RATE_LIMITED : GLQL_ERROR_NO_ACCESS;
    case HTTP_STATUS_SERVICE_UNAVAILABLE:
      return GLQL_ERROR_TIMEOUT;
    default:
      break;
  }

  const graphQLErrors = error.graphQLErrors?.length ? error.graphQLErrors : [error];

  for (const { extensions, message } of graphQLErrors) {
    const category = CATEGORY_BY_CODE[extensions?.code];
    if (category) return category;
    if (NOT_AUTHORIZED_MESSAGE.test(message || '')) return GLQL_ERROR_NO_ACCESS;
  }

  // No network response and no GraphQL payload means the query never ran: parse,
  // transform and presenter errors are deterministic, so a retry cannot help and
  // the message is the only way a dashboard author can fix the query.
  if (!error.networkError && !error.graphQLErrors?.length && !isRuntimeError(error)) {
    return GLQL_ERROR_INVALID_QUERY;
  }

  return GLQL_ERROR_GENERIC;
};
