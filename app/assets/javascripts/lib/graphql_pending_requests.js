// Counts in-flight Apollo requests behind `window.pendingApolloRequests`, which
// `wait_for_requests` polls in feature specs and QA. This module imports nothing,
// so the Vue 3 build never duplicates it and every Vue lane shares one counter.

const apolloClients = [];
let nonDedupedOperations = 0;

export const registerApolloClient = (client) => {
  apolloClients.push(client);
};

export const startNonDedupedOperation = () => {
  nonDedupedOperations += 1;
};

export const finishNonDedupedOperation = () => {
  nonDedupedOperations -= 1;
};

// Deduplicated queries never reach the link chain, so they are counted from each
// client's `inFlightLinkObservables`. Operations that opt out of deduplication
// (`forceFetch` in their context) do not use it, so a link counts them instead.
// https://www.apollographql.com/docs/react/v2/networking/network-layer/#query-deduplication
Object.defineProperty(window, 'pendingApolloRequests', {
  get() {
    return apolloClients.reduce(
      (sum, ac) => sum + (ac?.queryManager?.inFlightLinkObservables?.size || 0),
      nonDedupedOperations,
    );
  },
});
