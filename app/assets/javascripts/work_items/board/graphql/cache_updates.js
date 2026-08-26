import produce from 'immer';
import { cloneDeep } from 'lodash-es';
import { getWorkItemsConnection } from '~/work_items/utils';

// Clones the card so we have our own copy to reinsert into the target column,
// instead of a reference into the cache we're about to remove it from.
export const readWorkItemFromColumn = ({ cache, query, variables, workItemId, useRestApi }) => {
  const data = cache.readQuery({ query, variables });
  const node = getWorkItemsConnection(data, useRestApi)?.nodes?.find(
    (item) => item.id === workItemId,
  );
  return node ? cloneDeep(node) : null;
};

// Snapshot of a column's order before a move, used to work out the
// moveBeforeId/moveAfterId for the card landing there.
export const readWorkItemsFromColumn = ({ cache, query, variables, useRestApi }) => {
  const data = cache.readQuery({ query, variables });
  return getWorkItemsConnection(data, useRestApi)?.nodes ?? [];
};

// A column can be missing from the cache if it's collapsed or hasn't loaded
// yet. When that happens we just do nothing, so the move still succeeds.
export const removeWorkItemFromColumn = ({ cache, query, variables, workItemId, useRestApi }) => {
  cache.updateQuery({ query, variables }, (sourceData) => {
    if (!getWorkItemsConnection(sourceData, useRestApi)) {
      return sourceData;
    }

    return produce(sourceData, (draftData) => {
      const { nodes } = getWorkItemsConnection(draftData, useRestApi);
      const index = nodes.findIndex((item) => item.id === workItemId);
      if (index !== -1) {
        nodes.splice(index, 1);
      }
    });
  });
};

// Inserts the card at `index`. `patchCard`, if given, runs on the inserted
// clone so its grouped attribute (e.g. status) already matches the target
// column while the mutation is still in flight.
export const addWorkItemToColumn = ({
  cache,
  query,
  variables,
  workItem,
  index,
  patchCard,
  useRestApi,
}) => {
  cache.updateQuery({ query, variables }, (sourceData) => {
    if (!getWorkItemsConnection(sourceData, useRestApi)) {
      return sourceData;
    }

    return produce(sourceData, (draftData) => {
      const { nodes } = getWorkItemsConnection(draftData, useRestApi);
      if (nodes.some((item) => item.id === workItem.id)) {
        return;
      }

      const node = cloneDeep(workItem);
      if (patchCard) {
        patchCard(node);
      }

      nodes.splice(index, 0, node);
    });
  });
};

// The count-only query has its own cache entry, separate from the list query,
// so moving a card doesn't update the count for free — we have to do it here.
export const adjustWorkItemCountInColumn = ({ cache, query, variables, delta }) => {
  cache.updateQuery({ query, variables }, (sourceData) => {
    const connection = sourceData?.namespace?.workItems;
    if (typeof connection?.count !== 'number') {
      return sourceData;
    }

    return produce(sourceData, (draftData) => {
      const draft = draftData.namespace.workItems;
      draft.count = Math.max(0, draft.count + delta);
    });
  });
};
