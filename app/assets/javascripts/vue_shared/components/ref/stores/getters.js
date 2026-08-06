/** Returns `true` if the query string looks like it could be a commit SHA */
export const isQueryPossiblyASha = ({ query }) => /^[0-9a-f]{4,40}$/i.test(query);

/** Returns `true` if there is at least one in-progress request */
export const isLoading = ({ requestCount }) => requestCount > 0;
