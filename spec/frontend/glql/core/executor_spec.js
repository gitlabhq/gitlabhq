import { gql } from '@apollo/client/core';
import Executor, {
  execute,
  forget,
  resolveToScalar,
  transformGIDToString,
} from '~/glql/core/executor';
import createDefaultClient from '~/lib/graphql';
import setWindowLocation from 'helpers/set_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { MOCK_ISSUES } from '../mock_data';

jest.mock('~/lib/graphql', () => ({
  __esModule: true,
  default: jest.fn(),
  fetchPolicies: { NO_CACHE: 'no-cache' },
}));

const MOCK_QUERY_RESPONSE = { project: { issues: MOCK_ISSUES } };

describe('Executor', () => {
  let executor;
  let queryFn;

  // A new client object per call, so a test can tell a shared client from a fresh one.
  const mockQueryResponse = (...responses) => {
    queryFn = jest.fn();
    responses.forEach((response) => {
      queryFn.mockResolvedValueOnce({ data: response });
    });
    createDefaultClient.mockImplementation(() => ({
      query: queryFn,
    }));
  };

  beforeEach(() => {
    gon.current_username = 'foobar';
    Executor.sharedContexts = {};
    Executor.taskQueues = {};
    mockQueryResponse(MOCK_QUERY_RESPONSE);
    executor = new Executor().init(createDefaultClient());
  });

  afterEach(() => {
    delete gon.current_username;
  });

  it('executes a query using a graphql client', async () => {
    const data = await executor.execute(`
      {
        issues(assigneeUsernames: "foobar", first: 100) {
          nodes { id iid title webUrl reference state type }
          pageInfo { endCursor hasNextPage }
        }
      }
      `);

    expect(data).toEqual(MOCK_QUERY_RESPONSE);
  });

  describe('when the signal is aborted before the query leaves the queue', () => {
    it('rejects without sending the query', async () => {
      const controller = new AbortController();
      controller.abort(new Error('Discarded'));

      await expect(
        executor.execute('{ issues { nodes { id } } }', {}, { signal: controller.signal }),
      ).rejects.toThrow('Discarded');
      expect(queryFn).not.toHaveBeenCalled();
    });
  });

  it('executes a query with variables', async () => {
    const mockEpicQuery = `query GLQL { group(fullPath: "gitlab-org") { epics(iid: "123") { id } } }`;
    const mockIssueQuery = `query GLQL($epicId: String) { project(fullPath: "gitlab-org/gitlab") { issues(epicId: $epicId) { nodes { id title} } } }`;

    const mockEpicResponse = { group: { epics: [{ id: 'gid://gitlab/Epic/123' }] } };
    const mockIssueResponse = { project: { issues: { nodes: MOCK_ISSUES } } };

    mockQueryResponse(mockEpicResponse, mockIssueResponse);
    executor = new Executor().init(createDefaultClient());

    const data = await executor.execute(mockIssueQuery, {
      epicId: { value: mockEpicQuery, type: 'String' },
    });

    expect(data).toEqual(mockIssueResponse);
    expect(queryFn).toHaveBeenCalledTimes(2);
    expect(queryFn).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        query: gql`
          ${mockEpicQuery}
        `,
      }),
    );
    expect(queryFn).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        query: gql`
          ${mockIssueQuery}
        `,
        variables: {
          epicId: '123',
        },
      }),
    );
  });

  describe('task queues', () => {
    it('keeps one queue per name, with dashboards on their own', () => {
      expect(Executor.taskQueue()).toBe(Executor.taskQueue('glql-queue-default'));
      expect(Executor.taskQueue('glql-queue-dashboard')).toBe(
        Executor.taskQueue('glql-queue-dashboard'),
      );
      expect(Executor.taskQueue('glql-queue-dashboard')).not.toBe(Executor.taskQueue());
    });

    it('falls back to the default queue for an unknown name', () => {
      expect(Executor.taskQueue('glql-queue-typo')).toBe(Executor.taskQueue());
    });

    it('runs one request at a time by default and eight for dashboards', () => {
      expect(Executor.taskQueue().concurrencyLimit).toBe(1);
      expect(Executor.taskQueue('glql-queue-dashboard').concurrencyLimit).toBe(8);
    });

    it('does not hold a dashboard request behind the default queue', async () => {
      const variablesFor = (name) => ({ name: { type: 'String', value: name } });
      const sentRequests = () => queryFn.mock.calls.map(([{ variables }]) => variables.name);
      let releaseFirst;

      queryFn.mockReset();
      queryFn.mockReturnValueOnce(
        new Promise((resolve) => {
          releaseFirst = resolve;
        }),
      );
      queryFn.mockResolvedValue({ data: MOCK_QUERY_RESPONSE });

      const query = 'query { issues { nodes { id } } }';
      const requests = [
        executor.execute(query, variablesFor('first')),
        executor.execute(query, variablesFor('second')),
        executor.execute(query, variablesFor('dashboard'), { queue: 'glql-queue-dashboard' }),
      ];
      await waitForPromises();

      expect(sentRequests()).toEqual(['first', 'dashboard']);

      releaseFirst({ data: MOCK_QUERY_RESPONSE });
      await Promise.all(requests);

      expect(sentRequests()).toEqual(['first', 'dashboard', 'second']);
    });
  });

  describe('clients', () => {
    const query = '{ issues { nodes { id } } }';

    beforeEach(() => {
      createDefaultClient.mockClear();
      queryFn.mockResolvedValue({ data: MOCK_QUERY_RESPONSE });
    });

    it.each(['glql-queue-default', 'glql-queue-dashboard'])(
      'shares one client between the requests of the %s queue',
      async (queue) => {
        await execute(query, {}, { queue });
        await execute('{ epics { nodes { id } } }', {}, { queue });

        expect(createDefaultClient).toHaveBeenCalledTimes(1);
      },
    );

    it('serves requests that name no queue or an unknown one from the default client', async () => {
      await execute(query);
      await execute(query, {}, { queue: 'glql-queue-typo' });

      expect(createDefaultClient).toHaveBeenCalledTimes(1);
      expect(Executor.shared('glql-queue-typo').client).toBe(Executor.shared().client);
    });

    // The normalized cache keys rows by field and arguments, but GLQL panels select their
    // metrics and dimensions, so two panels' rows would land in the same cache entry.
    it("turns off Apollo's own cache for every shared client", () => {
      Executor.shared('glql-queue-default');
      Executor.shared('glql-queue-dashboard');

      expect(createDefaultClient.mock.calls).toEqual([
        [{}, { path: '/api/glql?', fetchPolicy: 'no-cache' }],
        [{}, { path: '/api/glql?', fetchPolicy: 'no-cache' }],
      ]);
    });

    // The endpoint carries the page's namespace, so a client is only shared within one.
    it('keeps a shared client per namespace', () => {
      setWindowLocation('/groups/gitlab-org/-/analytics/dashboards/dap_impact');
      const groupClient = Executor.shared('glql-queue-dashboard').client;

      setWindowLocation('/gitlab-org/gitlab/-/analytics/dashboards/dap_impact');
      const projectClient = Executor.shared('glql-queue-dashboard').client;

      expect(groupClient).not.toBe(projectClient);
      expect(createDefaultClient.mock.calls.map(([, config]) => config.path)).toEqual([
        '/api/glql?group=gitlab-org',
        '/api/glql?project=gitlab-org%2Fgitlab',
      ]);
    });
  });

  describe('result cache', () => {
    const DASHBOARD = { queue: 'glql-queue-dashboard' };
    const query = 'query GLQL($limit: Int) { issues(first: $limit) { nodes { id } } }';
    const variables = { limit: { type: 'Int', value: 20 } };
    const page = (limit) => ({ limit: { type: 'Int', value: limit } });
    const FIRST = { issues: { nodes: [{ id: 1 }] } };
    const SECOND = { issues: { nodes: [{ id: 2 }] } };

    // Every request stays pending until its release, in the order the requests were sent.
    const holdRequests = () => {
      const releases = [];
      queryFn.mockReset();
      queryFn.mockImplementation(
        () =>
          new Promise((resolve) => {
            releases.push((data) => resolve({ data }));
          }),
      );
      return releases;
    };

    beforeEach(() => {
      queryFn.mockReset();
      queryFn.mockResolvedValueOnce({ data: FIRST }).mockResolvedValue({ data: SECOND });
    });

    it('answers an identical dashboard query without a second request', async () => {
      expect(await execute(query, variables, DASHBOARD)).toEqual(FIRST);
      expect(await execute(query, variables, DASHBOARD)).toEqual(FIRST);
      expect(queryFn).toHaveBeenCalledTimes(1);
    });

    it('keys the cache by query text and variables', async () => {
      await execute(query, variables, DASHBOARD);
      await execute(query, { limit: { type: 'Int', value: 100 } }, DASHBOARD);
      await execute(query.replace('id', 'iid'), variables, DASHBOARD);

      expect(queryFn).toHaveBeenCalledTimes(3);
    });

    it('does not cache a failed request', async () => {
      queryFn.mockReset();
      queryFn.mockRejectedValueOnce(new Error('boom')).mockResolvedValue({ data: FIRST });

      await expect(execute(query, variables, DASHBOARD)).rejects.toThrow('boom');
      expect(await execute(query, variables, DASHBOARD)).toEqual(FIRST);
      expect(queryFn).toHaveBeenCalledTimes(2);
    });

    it('does not cache requests from embedded blocks', async () => {
      expect(await execute(query, variables)).toEqual(FIRST);
      expect(await execute(query, variables)).toEqual(SECOND);
      expect(queryFn).toHaveBeenCalledTimes(2);
    });

    it('shares one request between identical requests in flight', async () => {
      const releases = holdRequests();

      const requests = Array.from({ length: 7 }, () => execute(query, variables, DASHBOARD));
      await waitForPromises();
      releases[0](FIRST);

      expect(await Promise.all(requests)).toEqual(Array(7).fill(FIRST));
      expect(queryFn).toHaveBeenCalledTimes(1);
    });

    it('frees the slot of a request that joins one already running', async () => {
      const releases = holdRequests();

      // Eight that never finish fill the dashboard slots, so both identical requests have to wait.
      const blockers = Array.from({ length: 8 }, (_, i) =>
        execute(query, page(101 + i), DASHBOARD),
      );
      const leader = execute(query, page(5), DASHBOARD);
      const follower = execute(query, page(5), DASHBOARD);
      await waitForPromises();
      expect(queryFn).toHaveBeenCalledTimes(8);

      releases[0](FIRST);
      await waitForPromises();
      releases[1](FIRST);
      await waitForPromises();
      expect(queryFn).toHaveBeenCalledTimes(9);

      // The follower joined the leader, so its slot is free for an unrelated request at once.
      const other = execute(query.replace('issues', 'mergeRequests'), page(5), DASHBOARD);
      await waitForPromises();
      expect(queryFn).toHaveBeenCalledTimes(10);

      releases.slice(2).forEach((release) => release(SECOND));
      expect(await Promise.all([leader, follower])).toEqual([SECOND, SECOND]);
      await Promise.all([...blockers, other]);
    });

    it('resolves a repeated subquery variable from the cache as well', async () => {
      const subquery = 'query GLQL { group(fullPath: "gitlab-org") { epics(iid: "123") { id } } }';
      const withEpic = { epicId: { type: 'String', value: subquery } };
      queryFn.mockReset();
      queryFn.mockImplementation(({ variables: sent }) =>
        Promise.resolve({
          data: sent.epicId ? FIRST : { group: { epics: [{ id: 'gid://gitlab/Epic/123' }] } },
        }),
      );

      expect(await execute(query, withEpic, DASHBOARD)).toEqual(FIRST);
      expect(await execute(query, withEpic, DASHBOARD)).toEqual(FIRST);

      expect(queryFn).toHaveBeenCalledTimes(2);
      expect(queryFn).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({ variables: { epicId: '123' } }),
      );
    });

    describe('when the signal is aborted before the cache is read', () => {
      it('rejects instead of answering from the cache', async () => {
        await execute(query, variables, DASHBOARD);
        const controller = new AbortController();
        controller.abort(new Error('Discarded'));

        await expect(
          execute(query, variables, { ...DASHBOARD, signal: controller.signal }),
        ).rejects.toThrow('Discarded');
        expect(queryFn).toHaveBeenCalledTimes(1);
      });
    });

    // The cache dedupes in-flight requests itself. Apollo's deduplication would hand a request
    // made after a reload the result of the one the reload discarded.
    it("turns off Apollo's deduplication for cached requests", async () => {
      await execute(query, variables, DASHBOARD);

      expect(queryFn).toHaveBeenCalledWith(
        expect.objectContaining({ context: { queryDeduplication: false } }),
      );
    });

    describe('forget', () => {
      const PANEL = { ...DASHBOARD, tag: 'type = Issue' };
      const OTHER_PANEL = { ...DASHBOARD, tag: 'type = MergeRequest' };
      const otherQuery = query.replace('issues', 'mergeRequests');

      beforeEach(async () => {
        await execute(query, variables, PANEL);
        await execute(otherQuery, variables, OTHER_PANEL);
        queryFn.mockClear();
      });

      it('fetches the forgotten tag again and keeps the rest cached', async () => {
        forget('type = Issue', 'glql-queue-dashboard');

        expect(await execute(query, variables, PANEL)).toEqual(SECOND);
        expect(await execute(otherQuery, variables, OTHER_PANEL)).toEqual(SECOND);
        expect(queryFn).toHaveBeenCalledTimes(1);
      });

      it('drops a result every panel that fetched it shares', async () => {
        await execute(query, variables, OTHER_PANEL);
        forget('type = MergeRequest', 'glql-queue-dashboard');

        await execute(query, variables, PANEL);
        await execute(otherQuery, variables, OTHER_PANEL);
        expect(queryFn).toHaveBeenCalledTimes(2);
      });

      it('does not let a request that was running before a reload fill the cache', async () => {
        let finishStale;
        queryFn.mockReset();
        queryFn
          .mockImplementationOnce(
            () =>
              new Promise((resolve) => {
                finishStale = () => resolve({ data: FIRST });
              }),
          )
          .mockResolvedValue({ data: SECOND });

        const stale = execute(query, page(5), PANEL);
        await waitForPromises();
        forget('type = Issue', 'glql-queue-dashboard');

        const fresh = execute(query, page(5), PANEL);
        await waitForPromises();
        finishStale();

        expect(await stale).toEqual(FIRST);
        expect(await fresh).toEqual(SECOND);
        expect(await execute(query, page(5), PANEL)).toEqual(SECOND);
        expect(queryFn).toHaveBeenCalledTimes(2);
      });

      it('drops the request a queued panel would have joined when that panel reloads', async () => {
        const releases = holdRequests();
        const controller = new AbortController();
        const WAITING = { ...DASHBOARD, tag: 'type = Incident' };

        // Eight that never finish fill the dashboard slots, so the leader and the waiting panel's
        // identical request both queue, and only the leader itself gets to tag the entry it sets.
        const blockers = Array.from({ length: 8 }, (_, i) =>
          execute(query, page(101 + i), DASHBOARD),
        );
        const leader = execute(query, page(5), PANEL);
        const waiting = execute(query, page(5), { ...WAITING, signal: controller.signal });
        // Rejected once a slot frees, before the assertion below gets to it: keep that handled.
        waiting.catch(() => {});
        await waitForPromises();
        releases[0](FIRST);
        await waitForPromises();
        expect(queryFn).toHaveBeenCalledTimes(9);

        // The waiting panel reloads: its resolver goes, its entries are forgotten, a new one asks.
        controller.abort(new Error('Discarded'));
        forget('type = Incident', 'glql-queue-dashboard');
        const reloaded = execute(query, page(5), WAITING);
        await waitForPromises();
        releases[1](FIRST);
        await waitForPromises();

        await expect(waiting).rejects.toThrow('Discarded');
        expect(queryFn).toHaveBeenCalledTimes(10);
        releases[8](FIRST);
        releases[9](SECOND);
        expect(await leader).toEqual(FIRST);
        expect(await reloaded).toEqual(SECOND);

        releases.slice(2, 8).forEach((release) => release(FIRST));
        await Promise.all(blockers);
      });

      it('keeps everything for an unknown tag', async () => {
        forget('type = Epic', 'glql-queue-dashboard');

        await execute(query, variables, PANEL);
        expect(queryFn).not.toHaveBeenCalled();
      });

      it('does nothing for a queue without a result cache', () => {
        createDefaultClient.mockClear();

        expect(() => forget('type = Issue')).not.toThrow();
        expect(createDefaultClient).not.toHaveBeenCalled();
      });

      describe('before the dashboard queue has made a request', () => {
        beforeEach(() => {
          Executor.sharedContexts = {};
          createDefaultClient.mockClear();
        });

        it('does not create a client', () => {
          forget('type = Issue', 'glql-queue-dashboard');

          expect(createDefaultClient).not.toHaveBeenCalled();
        });
      });
    });
  });
});

describe('resolveToScalar', () => {
  it('returns the scalar value for a simple object', () => {
    expect(resolveToScalar({ id: 42 })).toBe(42);
  });

  it('recursively resolves nested objects', () => {
    expect(resolveToScalar({ foo: { bar: { baz: 'value' } } })).toBe('value');
  });

  it('ignores __typename keys', () => {
    expect(resolveToScalar({ __typename: 'Type', id: 'abc' })).toBe('abc');
  });
});

describe('transformGIDToString', () => {
  it('returns the last part of a GID string when type is String', () => {
    expect(transformGIDToString('gid://gitlab/Issue/123', 'String')).toBe('123');
  });

  it('returns the original data if type is not String', () => {
    expect(transformGIDToString('gid://gitlab/Issue/123', 'ID')).toBe('gid://gitlab/Issue/123');
  });

  it('returns undefined if data is undefined and type is String', () => {
    expect(transformGIDToString(undefined, 'String')).toBeUndefined();
  });
});
