import produce from 'immer';
import { cloneDeep } from 'lodash-es';

const getConnection = (data) => data?.namespace?.workItems;

// Deep snapshot of the moved card so it can be reinserted into the target column;
// null when the column or item is absent.
export const readWorkItemFromColumn = ({ cache, query, variables, workItemId }) => {
  const data = cache.readQuery({ query, variables });
  const node = getConnection(data)?.nodes?.find((item) => item.id === workItemId);
  return node ? cloneDeep(node) : null;
};

// Pre-move snapshot of a column's ordered work items; empty when the column is
// absent from the cache. Used to compute relative-position ids for a move.
export const readWorkItemsFromColumn = ({ cache, query, variables }) => {
  const data = cache.readQuery({ query, variables });
  return getConnection(data)?.nodes ?? [];
};

// No-op on a missing cache entry, so a move still works when a sibling column is unloaded.
export const removeWorkItemFromColumn = ({ cache, query, variables, workItemId }) => {
  cache.updateQuery({ query, variables }, (sourceData) => {
    if (!getConnection(sourceData)) {
      return sourceData;
    }

    return produce(sourceData, (draftData) => {
      const { nodes } = getConnection(draftData);
      const index = nodes.findIndex((item) => item.id === workItemId);
      if (index !== -1) {
        nodes.splice(index, 1);
      }
    });
  });
};

// Inserts at index and runs the optional `patchCard` callback on the inserted
// (cloned) node so its grouped attribute matches the target column during the
// optimistic window. No-op on a missing cache entry.
export const addWorkItemToColumn = ({ cache, query, variables, workItem, index, patchCard }) => {
  cache.updateQuery({ query, variables }, (sourceData) => {
    if (!getConnection(sourceData)) {
      return sourceData;
    }

    return produce(sourceData, (draftData) => {
      const { nodes } = getConnection(draftData);
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

// Adjusts a column's total count (the count-only query lives in its own cache entry,
// so card-move updates to the connection don't touch it). No-op on a missing entry.
export const adjustWorkItemCountInColumn = ({ cache, query, variables, delta }) => {
  cache.updateQuery({ query, variables }, (sourceData) => {
    const connection = getConnection(sourceData);
    if (typeof connection?.count !== 'number') {
      return sourceData;
    }

    return produce(sourceData, (draftData) => {
      const draft = getConnection(draftData);
      draft.count = Math.max(0, draft.count + delta);
    });
  });
};
