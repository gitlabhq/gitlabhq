import gql from 'graphql-tag';
import { ApolloClient, ApolloLink, InMemoryCache } from '@apollo/client/core';
import {
  WI_REALTIME_TAG_KEY,
  COUNT_OPERATIONS,
  REALTIME_TAG_TTL_MS,
  markRealtimeRefetch,
  getRealtimeRequestTagLink,
} from '~/work_items/list/graphql/realtime_request_tag';

const GET_WORK_ITEMS_SLIM_QUERY = gql`
  query getWorkItemsSlim {
    foo
  }
`;
const SOME_OTHER_QUERY = gql`
  query someOtherQuery {
    foo
  }
`;

// `testApolloLink` (helpers/test_apollo_link) doesn't forward `variables`, which the tests below
// need to tell requests apart, so this runs the link directly instead.
const runLink = (link, { query = GET_WORK_ITEMS_SLIM_QUERY, variables, context = {} } = {}) =>
  new Promise((resolve) => {
    const terminatingLink = new ApolloLink((operation) => {
      resolve(operation);
      return null;
    });

    const client = new ApolloClient({
      link: ApolloLink.from([link, terminatingLink]),
      cache: new InMemoryCache(),
    });

    client.query({ query, variables, context });
  });

describe('~/work_items/list/graphql/realtime_request_tag', () => {
  afterEach(() => {
    getRealtimeRequestTagLink.cache.clear();
  });

  describe('getRealtimeRequestTagLink', () => {
    it('returns a memoized link', () => {
      expect(getRealtimeRequestTagLink()).toBe(getRealtimeRequestTagLink());
    });

    it('leaves an operation with no pending mark untagged', async () => {
      const operation = await runLink(getRealtimeRequestTagLink());

      expect(operation.getContext().requestTag).toBeUndefined();
    });

    it('tags the next request for a marked operation', async () => {
      markRealtimeRefetch('match', ['getWorkItemsSlim']);

      const operation = await runLink(getRealtimeRequestTagLink());

      expect(operation.getContext().requestTag).toEqual({ [WI_REALTIME_TAG_KEY]: 'match' });
    });

    it('does not tag an operation not covered by the mark', async () => {
      markRealtimeRefetch('match', ['getWorkItemsSlim']);

      const operation = await runLink(getRealtimeRequestTagLink(), {
        query: SOME_OTHER_QUERY,
      });

      expect(operation.getContext().requestTag).toBeUndefined();
    });

    it('does not overwrite a requestTag the caller already set', async () => {
      markRealtimeRefetch('match', ['getWorkItemsSlim']);

      const operation = await runLink(getRealtimeRequestTagLink(), {
        context: { requestTag: { [WI_REALTIME_TAG_KEY]: 'match_manual' } },
      });

      expect(operation.getContext().requestTag).toEqual({
        [WI_REALTIME_TAG_KEY]: 'match_manual',
      });
    });

    it('marks every distinct variables set exactly once, e.g. one per board column', async () => {
      markRealtimeRefetch('count', ['getWorkItemsSlim']);

      const firstColumn = await runLink(getRealtimeRequestTagLink(), {
        variables: { id: 'column-1' },
      });
      const secondColumn = await runLink(getRealtimeRequestTagLink(), {
        variables: { id: 'column-2' },
      });
      const firstColumnAgain = await runLink(getRealtimeRequestTagLink(), {
        variables: { id: 'column-1' },
      });

      expect(firstColumn.getContext().requestTag).toEqual({ [WI_REALTIME_TAG_KEY]: 'count' });
      expect(secondColumn.getContext().requestTag).toEqual({ [WI_REALTIME_TAG_KEY]: 'count' });
      expect(firstColumnAgain.getContext().requestTag).toBeUndefined();
    });

    it('stops tagging once the mark has expired', async () => {
      jest.spyOn(Date, 'now').mockReturnValue(0);
      markRealtimeRefetch('match', ['getWorkItemsSlim']);

      Date.now.mockReturnValue(REALTIME_TAG_TTL_MS + 1);
      const operation = await runLink(getRealtimeRequestTagLink());

      expect(operation.getContext().requestTag).toBeUndefined();
    });
  });

  describe('COUNT_OPERATIONS', () => {
    it('is the count-only subset of the refetchable operations', () => {
      expect(COUNT_OPERATIONS).toEqual([
        'getWorkItemsCountOnly',
        'getWorkItemsCountOnlyEE',
        'hasWorkItems',
      ]);
    });
  });
});
