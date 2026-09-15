import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { setError, updateIssueCountAndWeight } from '~/boards/graphql/cache_updates';
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
