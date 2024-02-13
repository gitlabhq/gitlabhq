import produce from 'immer';
import { toNumber } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { defaultClient } from '~/graphql_shared/issuable_client';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import { listsDeferredQuery } from 'ee_else_ce/boards/constants';

import setErrorMutation from './client/set_error.mutation.graphql';

export function removeItemFromList({
  query,
  variables,
  boardType,
  id,
  issuableType,
  listId = undefined,
  cache,
}) {
  cache.updateQuery({ query, variables }, (sourceData) =>
    produce(sourceData, (draftData) => {
      const list = listId
        ? draftData[boardType]?.board.lists.nodes.find((l) => l.id === listId)
        : draftData[boardType].board.lists.nodes[0];
      const { nodes: items } = list[`${issuableType}s`];
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
  listId = undefined,
  cache,
}) {
  cache.updateQuery({ query, variables }, (sourceData) =>
    produce(sourceData, (draftData) => {
      const list = listId
        ? draftData[boardType]?.board.lists.nodes.find((l) => l.id === listId)
        : draftData[boardType].board.lists.nodes[0];
      const { nodes: items } = list[`${issuableType}s`];
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
          totalIssueWeight: boardList.totalIssueWeight - issue.weight,
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
        ...(issue.weight
          ? { totalIssueWeight: toNumber(boardList.totalIssueWeight) + issue.weight }
          : {}),
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
            ...epicBoardList.metadata,
            epicsCount: epicBoardList.metadata.epicsCount - 1,
            totalWeight: epicBoardList.metadata.totalWeight - epicWeight,
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
          ...epicBoardList.metadata,
          epicsCount: epicBoardList.metadata.epicsCount + 1,
          totalWeight: epicBoardList.metadata.totalWeight + epicWeight,
        },
      },
    }),
  );
}

export function updateListWeightCache({ weight, listId, cache }) {
  cache.updateQuery(
    {
      query: listQuery,
      variables: { id: listId },
    },
    ({ boardList }) => ({
      boardList: {
        ...boardList,
        totalIssueWeight: toNumber(boardList.totalIssueWeight) + weight,
      },
    }),
  );
}

export function setError({ message, error, captureError = true }) {
  defaultClient.mutate({
    mutation: setErrorMutation,
    variables: {
      error: message,
    },
  });

  if (captureError) {
    Sentry.captureException(error);
  }
}
