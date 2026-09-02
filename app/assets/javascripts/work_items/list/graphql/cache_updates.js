import { TYPENAME_NAMESPACE, TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import workItemIdFragment from '~/work_items/graphql/work_item_id.fragment.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import { boardColumnQuery } from '~/work_items/board/utils';
import { getWorkItemsConnection } from '~/work_items/utils';

// The backend rejects a `workItems(ids:)` filter longer than this (`WorkItems::
// SharedFilterArguments::MAX_FIELD_LIMIT`), so a flush bigger than this can't be checked in one go.
export const MAX_MATCH_IDS = 100;

const ACTION_CREATED = 'CREATED';
const ACTION_UPDATED = 'UPDATED';
const ACTION_DELETED = 'DELETED';

// A create that is followed by an edit must stay a create, otherwise the new work item is not in
// the cache yet and the coalesced change gets discarded.
const ACTION_PRECEDENCE = [ACTION_UPDATED, ACTION_CREATED, ACTION_DELETED];

// `workItems` has no `keyArgs`, so every filter, page, board column and count-only query is a
// separate store entry. Omitting `args` clears all of them, and each active query refetches.
export const evictNamespaceWorkItems = (cache, namespaceId, { useRestApi = false } = {}) => {
  cache.evict({
    id: cache.identify({ __typename: TYPENAME_NAMESPACE, id: namespaceId }),
    fieldName: 'workItems',
  });

  // The REST connection isn't nested under the namespace, so it needs its own eviction.
  if (useRestApi) {
    cache.evict({ fieldName: 'restWorkItems' });
  }

  cache.gc();
};

// Every cached connection drops the work item without a refetch, because Apollo filters dangling
// references out of list fields when reading. Callers run `cache.gc()` once per batch.
export const evictWorkItem = (cache, workItemId) => {
  cache.evict({ id: cache.identify({ __typename: TYPENAME_WORK_ITEM, id: workItemId }) });
};

// Re-runs the query the view already renders with, narrowed to just these ids — the server's
// answer is the visibility check, and Apollo normalizes whatever nodes come back into the cache
// as a side effect, patching them for free. Returns `null` when there are too many ids to ask about.
export const findMatchingWorkItems = async ({
  client,
  queryVariables,
  ids,
  useRestApi,
  isBoardView,
  glFeatures,
}) => {
  if (ids.length > MAX_MATCH_IDS) {
    return null;
  }

  let query = getWorkItemsSlimQuery;
  if (isBoardView) {
    query = boardColumnQuery(glFeatures);
  } else if (useRestApi) {
    query = getWorkItemsRestQuery;
  }

  const { data } = await client.query({
    query,
    variables: {
      ...queryVariables,
      ids,
      afterCursor: null,
      beforeCursor: null,
      firstPageSize: ids.length,
      lastPageSize: null,
    },
    fetchPolicy: 'network-only',
    context: { featureCategory: 'portfolio_management' },
  });

  return new Set(getWorkItemsConnection(data, useRestApi)?.nodes.map((node) => node.id) ?? []);
};

// The match query's `ids` argument gives it its own store entry, separate from the list's, because
// `workItems` has no `keyArgs` — nothing else merges into it, so it just needs clearing out.
export const dropMatchCacheEntries = (cache, namespaceId) => {
  const stripMatchEntry = (value, { storeFieldName, DELETE }) =>
    storeFieldName.includes('"ids":') ? DELETE : value;

  if (namespaceId) {
    cache.modify({
      id: cache.identify({ __typename: TYPENAME_NAMESPACE, id: namespaceId }),
      fields: { workItems: stripMatchEntry },
    });
  }
  cache.modify({ fields: { restWorkItems: stripMatchEntry } });
  cache.gc();
};

// True whenever the item could be on screen, but also true for items only cached as a
// child of something else, so this can say "cached" more often than the item is actually shown.
export const isWorkItemCached = (cache, workItemId) =>
  Boolean(
    cache.readFragment({
      id: cache.identify({ __typename: TYPENAME_WORK_ITEM, id: workItemId }),
      fragment: workItemIdFragment,
    }),
  );

export const mergeWorkItemChangeAction = (existing, incoming) =>
  ACTION_PRECEDENCE.indexOf(incoming) >= ACTION_PRECEDENCE.indexOf(existing) ? incoming : existing;

export const groupWorkItemChanges = (changes) => {
  const entries = [...changes];
  const idsWhere = (predicate) =>
    entries.filter(([, action]) => predicate(action)).map(([workItemId]) => workItemId);

  return {
    created: idsWhere((action) => action === ACTION_CREATED),
    deleted: idsWhere((action) => action === ACTION_DELETED),
    // Fall back to UPDATED. This will also catch any new event types we add without specific handling.
    updated: idsWhere((action) => action !== ACTION_CREATED && action !== ACTION_DELETED),
  };
};
