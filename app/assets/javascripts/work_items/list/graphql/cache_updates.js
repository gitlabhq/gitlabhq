import { TYPENAME_NAMESPACE, TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import workItemIdFragment from '~/work_items/graphql/work_item_id.fragment.graphql';

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
