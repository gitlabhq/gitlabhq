import produce from 'immer';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import { listsDeferredQuery } from 'ee_else_ce/boards/constants';

export function removeItemFromList({ query, variables, boardType, id, issuableType, cache }) {
  cache.updateQuery({ query, variables }, (sourceData) =>
    produce(sourceData, (draftData) => {
      const { nodes: items } = draftData[boardType].board.lists.nodes[0][`${issuableType}s`];
      items.splice(
        items.findIndex((item) => item.id === id),
        1,
      );
    }),
  );
}

export function addItemToList({
  query,
  variables,
  boardType,
  issuable,
  newIndex,
  issuableType,
  cache,
}) {
  cache.updateQuery({ query, variables }, (sourceData) =>
    produce(sourceData, (draftData) => {
      const { nodes: items } = draftData[boardType].board.lists.nodes[0][`${issuableType}s`];
      items.splice(newIndex, 0, issuable);
    }),
  );
}

export function updateIssueCountAndWeight({
  fromListId,
  toListId,
  filterParams,
  issuable: issue,
  shouldClone,
  cache,
}) {
  if (!shouldClone) {
    cache.updateQuery(
      {
        query: listQuery,
        variables: { id: fromListId, filters: filterParams },
      },
      ({ boardList }) => ({
        boardList: {
          ...boardList,
          issuesCount: boardList.issuesCount - 1,
          totalWeight: boardList.totalWeight - issue.weight,
        },
      }),
    );
  }

  cache.updateQuery(
    {
      query: listQuery,
      variables: { id: toListId, filters: filterParams },
    },
    ({ boardList }) => ({
      boardList: {
        ...boardList,
        issuesCount: boardList.issuesCount + 1,
        totalWeight: boardList.totalWeight + issue.weight,
      },
    }),
  );
}

export function updateEpicsCount({
  issuableType,
  filterParams,
  fromListId,
  toListId,
  issuable: epic,
  shouldClone,
  cache,
}) {
  const epicWeight = epic.descendantWeightSum.openedIssues + epic.descendantWeightSum.closedIssues;
  if (!shouldClone) {
    cache.updateQuery(
      {
        query: listsDeferredQuery[issuableType].query,
        variables: { id: fromListId, filters: filterParams },
      },
      ({ epicBoardList }) => ({
        epicBoardList: {
          ...epicBoardList,
          metadata: {
            epicsCount: epicBoardList.metadata.epicsCount - 1,
            totalWeight: epicBoardList.metadata.totalWeight - epicWeight,
            ...epicBoardList.metadata,
          },
        },
      }),
    );
  }

  cache.updateQuery(
    {
      query: listsDeferredQuery[issuableType].query,
      variables: { id: toListId, filters: filterParams },
    },
    ({ epicBoardList }) => ({
      epicBoardList: {
        ...epicBoardList,
        metadata: {
          epicsCount: epicBoardList.metadata.epicsCount + 1,
          totalWeight: epicBoardList.metadata.totalWeight + epicWeight,
          ...epicBoardList.metadata,
        },
      },
    }),
  );
}
