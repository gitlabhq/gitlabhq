/** Returns `true` if there is at least one in-progress request */
export const isLoading = ({ requestCount }) => requestCount > 0;
