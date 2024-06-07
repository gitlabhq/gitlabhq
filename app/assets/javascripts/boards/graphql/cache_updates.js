import produce from 'immer';
import { toNumber, uniq } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { defaultClient } from '~/graphql_shared/issuable_client';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import { listsDeferredQuery } from 'ee_else_ce/boards/constants';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { TYPE_ISSUE } from '~/issues/constants';

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

export function identifyAffectedLists({
  client,
  item,
  issuableType,
  affectedListTypes,
  updatedAttributeIds,
}) {
  const allCache = client.cache.extract();
  const listIdsToRefetch = [];
  const type = capitalizeFirstCharacter(issuableType);
  const typename = issuableType === TYPE_ISSUE ? 'BoardList' : 'EpicList';

  Object.values(allCache).forEach((value) => {
    const issuablesField = Object.keys(value).find((key) => key.includes(`${issuableType}s:`));
    const issuables = value[issuablesField]?.nodes ?? [];

    /* eslint-disable no-underscore-dangle */
    if (value.__typename === typename) {
      // We identify the id of the attribute that was updated. In Apollo Cache, entries are stored in the following format:
      // UserCore:gid://gitlab/UserCore/1 (<type>:<global id>). We extract the id from the __ref field.
      const attributeId =
        value.assignee?.__ref.match(/UserCore:(.*)/)[1] ||
        value.label?.__ref.match(/Label:(.*)/)[1] ||
        value.milestone?.__ref.match(/Milestone:(.*)/)[1] ||
        value.iteration?.__ref.match(/Iteration:(.*)/)[1];

      // If the item is in the list, and lists of this type are affected, we need to refetch the list
      if (issuables.length > 0) {
        const issueExistsInList = issuables.some((i) => i.__ref === `${type}:${item.id}`);
        if (issueExistsInList && affectedListTypes.includes(value.listType)) {
          listIdsToRefetch.push(value.id);
        }
      }
      // If the item is not in the list, but the list has the attribute from affected attributes list
      // we need to refetch the list
      if (updatedAttributeIds.includes(attributeId)) {
        listIdsToRefetch.push(value.id);
      }
    }
    /* eslint-enable no-underscore-dangle */
  });

  return uniq(listIdsToRefetch);
}
