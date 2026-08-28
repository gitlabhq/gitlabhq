import gql from 'graphql-tag';
import waitForPromises from 'helpers/wait_for_promises';
import createDefaultClient from '~/lib/graphql';

const QUERY = gql`
  query getFoo {
    foo
  }
`;

const MUTATION = gql`
  mutation setFoo {
    setFoo
  }
`;

describe('window.pendingApolloRequests', () => {
  let client;
  let pendingFetches;

  const respondWith = (data) => ({
    ok: true,
    status: 200,
    text: () => Promise.resolve(JSON.stringify({ data })),
    headers: { get: () => null },
  });

  const resolveAllFetches = async (data) => {
    pendingFetches.forEach((resolve) => resolve(respondWith(data)));
    pendingFetches = [];
    await waitForPromises();
  };

  beforeEach(() => {
    window.gon = {};
    pendingFetches = [];
    jest.spyOn(global, 'fetch').mockImplementation(
      () =>
        new Promise((resolve) => {
          pendingFetches.push(resolve);
        }),
    );

    client = createDefaultClient();
  });

  afterEach(async () => {
    await resolveAllFetches({});
  });

  it('counts a deduplicated query while it is in flight', async () => {
    const query = client.query({ query: QUERY });
    await waitForPromises();

    expect(global.fetch).toHaveBeenCalledTimes(1);
    expect(window.pendingApolloRequests).toBe(1);

    await resolveAllFetches({ foo: 'bar' });
    await query;

    expect(window.pendingApolloRequests).toBe(0);
  });

  it('counts a mutation while it is in flight', async () => {
    const mutation = client.mutate({ mutation: MUTATION });
    await waitForPromises();

    expect(window.pendingApolloRequests).toBe(1);

    await resolveAllFetches({ setFoo: true });
    await mutation;

    expect(window.pendingApolloRequests).toBe(0);
  });

  describe('with queryDeduplication disabled', () => {
    const queryOptions = {
      query: QUERY,
      fetchPolicy: 'no-cache',
      context: { queryDeduplication: false },
    };

    it('counts each request while it is in flight', async () => {
      const queries = [client.query(queryOptions), client.query(queryOptions)];
      await waitForPromises();

      expect(global.fetch).toHaveBeenCalledTimes(2);
      expect(window.pendingApolloRequests).toBe(2);

      await resolveAllFetches({ foo: 'bar' });
      await Promise.all(queries);

      expect(window.pendingApolloRequests).toBe(0);
    });

    it('drains to exactly zero for a request that is unsubscribed before it completes', async () => {
      const subscription = client.watchQuery(queryOptions).subscribe({});
      await waitForPromises();

      expect(window.pendingApolloRequests).toBe(1);

      // The fetch is not aborted by unsubscribing, so the operation still
      // counts until its response arrives, and then only drains once.
      subscription.unsubscribe();
      await resolveAllFetches({ foo: 'bar' });

      expect(window.pendingApolloRequests).toBe(0);
    });
  });
});
