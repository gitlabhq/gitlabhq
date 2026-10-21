export const ARTIFACTS_EXPIRED_ERROR_MESSAGE = 'Test report artifacts not found';

// Number of suites fetched in parallel when loading every job's test cases for
// a global search, so we never fire one request per suite simultaneously.
export const SUITE_FETCH_CONCURRENCY = 4;

// Above this many jobs (suites) in a pipeline, global search is not started
// automatically. The user must opt in to search across jobs
export const SEARCH_ALL_SUITES_THRESHOLD = 20;
export const SEARCH_SCOPE_SUITE = 'suite';
export const SEARCH_SCOPE_ALL = 'all';

export const WRAP_SYMBOLS = ['::', '#', '.', '_', '-', '/', '\\'];
