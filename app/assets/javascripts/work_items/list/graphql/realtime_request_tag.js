import { memoize } from 'lodash-es';
import { ApolloLink } from '@apollo/client/core';

// Read by the `requestTag` hook in `lib/graphql.js` and appended to the request's query string —
// see there for why this needs to be a query param and not a header.
export const WI_REALTIME_TAG_KEY = 'wi_realtime';

// Every operation an eviction or `refetchQueries` can cause to re-fire, across list/table/board
// view and the REST/GraphQL API flag, CE and EE.
export const REFETCHABLE_OPERATIONS = [
  'getWorkItemsSlim',
  'getWorkItemsSlimEE',
  'getWorkItemsFull',
  'getWorkItemsFullEE',
  'getWorkItemsRest',
  'getWorkItemsRestEE',
  'getBoardWorkItems',
  'getBoardWorkItemsEE',
  'getWorkItemsCountOnly',
  'getWorkItemsCountOnlyEE',
  'hasWorkItems',
];

export const COUNT_OPERATIONS = [
  'getWorkItemsCountOnly',
  'getWorkItemsCountOnlyEE',
  'hasWorkItems',
];

// Apollo's post-eviction refetch fires on a later tick, not synchronously, so the mark has to
// outlive the call that set it. A few seconds covers that gap without risking a stale mark
// wrongly tagging an unrelated request much later (e.g. from a view that already unmounted).
export const REALTIME_TAG_TTL_MS = 5000;

const pendingCauses = new Map();

// One mark can cause several requests for the same operation — `refetchQueries` hits every
// board column's own count query — so `seen` (below) tags each distinct variables set exactly
// once instead of only the first.
export const markRealtimeRefetch = (cause, operationNames = REFETCHABLE_OPERATIONS) => {
  const expiresAt = Date.now() + REALTIME_TAG_TTL_MS;
  operationNames.forEach((operationName) => {
    pendingCauses.set(operationName, { cause, expiresAt, seen: new Set() });
  });
};

export const getRealtimeRequestTagLink = memoize(() => {
  return new ApolloLink((operation, forward) => {
    const pending = pendingCauses.get(operation.operationName);

    if (pending && Date.now() <= pending.expiresAt && !operation.getContext().requestTag) {
      const variablesKey = JSON.stringify(operation.variables);

      if (!pending.seen.has(variablesKey)) {
        pending.seen.add(variablesKey);
        operation.setContext((currentContext) => ({
          ...currentContext,
          requestTag: { [WI_REALTIME_TAG_KEY]: pending.cause },
        }));
      }
    }

    return forward(operation);
  });
});
