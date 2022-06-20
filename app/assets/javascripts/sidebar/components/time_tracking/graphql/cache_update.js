import produce from 'immer';

export function removeTimelogFromStore(store, deletedTimelogId, query, variables) {
  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    draftData.issuable.timelogs.nodes = draftData.issuable.timelogs.nodes.filter(
      ({ id }) => id !== deletedTimelogId,
    );
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
}
