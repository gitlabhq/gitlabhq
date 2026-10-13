import { InMemoryCache } from '@apollo/client/core';
import gql from 'graphql-tag';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  evictWorkItemForIssue,
  setError,
  updateIssueCountAndWeight,
} from '~/boards/graphql/cache_updates';
import { defaultClient } from '~/graphql_shared/issuable_client';
import setErrorMutation from '~/boards/graphql/client/set_error.mutation.graphql';

describe('updateIssueCountAndWeight', () => {
  const issue = { weight: 2 };
  const listData = {
    boardList: { id: 'gid://gitlab/List/1', issuesCount: 3, totalIssueWeight: 5 },
  };

  // Mimics ApolloCache.updateQuery: runs the updater with the cached data, or null when
  // the query is not in the cache, and records what it returns.
  const createCache = (cachedData) => {
    const written = [];
    return {
      written,
      updateQuery: jest.fn((options, update) => {
        const result = update(cachedData);
        if (result) written.push(result);
      }),
    };
  };

  it('updates the counts of both lists when they are cached', () => {
    const cache = createCache(listData);

    updateIssueCountAndWeight({ fromListId: 'from', toListId: 'to', issuable: issue, cache });

    expect(cache.written).toEqual([
      { boardList: { ...listData.boardList, issuesCount: 2, totalIssueWeight: 3 } },
      { boardList: { ...listData.boardList, issuesCount: 4, totalIssueWeight: 7 } },
    ]);
  });

  it('does not throw or write when a list is not in the cache yet', () => {
    const cache = createCache(null);

    expect(() =>
      updateIssueCountAndWeight({ fromListId: 'from', toListId: 'to', issuable: issue, cache }),
    ).not.toThrow();
    expect(cache.written).toEqual([]);
  });
});

describe('evictWorkItemForIssue', () => {
  const workItemQuery = gql`
    query workItem {
      workItem {
        id
        state
      }
    }
  `;

  const seedCache = (id) => {
    const cache = new InMemoryCache();
    cache.writeQuery({
      query: workItemQuery,
      data: { workItem: { __typename: 'WorkItem', id, state: 'OPEN' } },
    });
    return cache;
  };

  it('evicts the work item that shares the issue id', () => {
    const cache = seedCache('gid://gitlab/WorkItem/436');

    evictWorkItemForIssue({ cache, issueId: 'gid://gitlab/Issue/436' });

    expect(cache.extract()['WorkItem:gid://gitlab/WorkItem/436']).toBeUndefined();
  });

  it('does nothing when the issuable has no id, as in an optimistic response', () => {
    const cache = seedCache('gid://gitlab/WorkItem/436');

    evictWorkItemForIssue({ cache, issueId: undefined });

    expect(cache.extract()['WorkItem:gid://gitlab/WorkItem/436']).toMatchObject({
      id: 'gid://gitlab/WorkItem/436',
      state: 'OPEN',
    });
  });

  it('does nothing for an epic id, which names a different record', () => {
    const cache = seedCache('gid://gitlab/WorkItem/436');

    evictWorkItemForIssue({ cache, issueId: 'gid://gitlab/Epic/436' });

    expect(cache.extract()['WorkItem:gid://gitlab/WorkItem/436']).toMatchObject({
      id: 'gid://gitlab/WorkItem/436',
      state: 'OPEN',
    });
  });

  it('leaves work items with a different id in the cache', () => {
    const cache = seedCache('gid://gitlab/WorkItem/437');

    evictWorkItemForIssue({ cache, issueId: 'gid://gitlab/Issue/436' });

    expect(cache.extract()['WorkItem:gid://gitlab/WorkItem/437']).toMatchObject({
      id: 'gid://gitlab/WorkItem/437',
      state: 'OPEN',
    });
  });
});

describe('setError', () => {
  let sentryCaptureExceptionSpy;
  const errorMessage = 'Error';
  const error = new Error(errorMessage);

  beforeEach(() => {
    jest.spyOn(defaultClient, 'mutate').mockResolvedValue();
    sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');
  });

  it('calls setErrorMutation and capture Sentry error', () => {
    setError({ message: errorMessage, error });

    expect(defaultClient.mutate).toHaveBeenCalledWith({
      mutation: setErrorMutation,
      variables: { error: errorMessage },
    });

    expect(sentryCaptureExceptionSpy).toHaveBeenCalledWith(error);
  });

  it('does not capture Sentry error when captureError is false', () => {
    setError({ message: errorMessage, error, captureError: false });

    expect(defaultClient.mutate).toHaveBeenCalledWith({
      mutation: setErrorMutation,
      variables: { error: errorMessage },
    });

    expect(sentryCaptureExceptionSpy).not.toHaveBeenCalled();
  });
});
