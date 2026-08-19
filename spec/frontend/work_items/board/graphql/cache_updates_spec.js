import {
  readWorkItemFromColumn,
  readWorkItemsFromColumn,
  removeWorkItemFromColumn,
  addWorkItemToColumn,
  adjustWorkItemCountInColumn,
} from '~/work_items/board/graphql/cache_updates';

describe('board cache_updates', () => {
  const query = { fake: 'query' };
  const variables = { fake: 'variables' };
  const workItemA = { id: 'gid://gitlab/WorkItem/1', title: 'A' };
  const workItemB = { id: 'gid://gitlab/WorkItem/2', title: 'B' };
  const workItemC = { id: 'gid://gitlab/WorkItem/3', title: 'C' };

  const buildRestData = (nodes) => ({
    restWorkItems: { nodes },
  });

  const buildGraphqlData = (nodes) => ({
    namespace: { workItems: { nodes } },
  });

  const buildCountData = (count) => ({
    namespace: {
      workItems: {
        ...(typeof count === 'number' ? { count } : {}),
      },
    },
  });

  // Minimal cache stub that just holds a single "row" of data and lets the
  // helpers exercise both read and updateQuery flows.
  const createCache = (initialData) => {
    let stored = initialData;
    return {
      readQuery: jest.fn(() => stored),
      updateQuery: jest.fn((_options, updater) => {
        const result = updater(stored);
        if (result !== undefined) {
          stored = result;
        }
      }),
      getStored: () => stored,
    };
  };

  // The list helpers read/write different cache paths depending on the query in
  // use: `restWorkItems` when the REST @client field backs the board, or
  // `namespace.workItems` for the GraphQL query. Callers signal which path via
  // `useRestApi`, so we exercise both here.
  describe.each([
    {
      label: 'when useRestApi is true (top-level restWorkItems path)',
      useRestApi: true,
      buildData: buildRestData,
      getConnection: (data) => data?.restWorkItems,
    },
    {
      label: 'when useRestApi is false (nested namespace.workItems path)',
      useRestApi: false,
      buildData: buildGraphqlData,
      getConnection: (data) => data?.namespace?.workItems,
    },
  ])('$label', ({ useRestApi, buildData, getConnection }) => {
    describe('readWorkItemFromColumn', () => {
      it('returns a deep clone of the matching node', () => {
        const cache = createCache(buildData([workItemA, workItemB]));

        const result = readWorkItemFromColumn({
          cache,
          query,
          variables,
          workItemId: workItemA.id,
          useRestApi,
        });

        expect(result).toEqual(workItemA);
        expect(result).not.toBe(workItemA);
      });

      it('returns null when the item is not present', () => {
        const cache = createCache(buildData([workItemA]));

        const result = readWorkItemFromColumn({
          cache,
          query,
          variables,
          workItemId: workItemB.id,
          useRestApi,
        });

        expect(result).toBeNull();
      });

      it('returns null when the connection is missing', () => {
        const cache = createCache({});

        const result = readWorkItemFromColumn({
          cache,
          query,
          variables,
          workItemId: workItemA.id,
          useRestApi,
        });

        expect(result).toBeNull();
      });
    });

    describe('readWorkItemsFromColumn', () => {
      it('returns the connection nodes', () => {
        const cache = createCache(buildData([workItemA, workItemB]));

        const result = readWorkItemsFromColumn({ cache, query, variables, useRestApi });

        expect(result).toEqual([workItemA, workItemB]);
      });

      it('returns an empty array when the connection is missing', () => {
        const cache = createCache({});

        const result = readWorkItemsFromColumn({ cache, query, variables, useRestApi });

        expect(result).toEqual([]);
      });
    });

    describe('removeWorkItemFromColumn', () => {
      it('removes the matching node from the connection', () => {
        const cache = createCache(buildData([workItemA, workItemB]));

        removeWorkItemFromColumn({
          cache,
          query,
          variables,
          workItemId: workItemA.id,
          useRestApi,
        });

        expect(getConnection(cache.getStored()).nodes).toEqual([workItemB]);
      });

      it('is a no-op when the connection is missing', () => {
        const cache = createCache({});

        removeWorkItemFromColumn({
          cache,
          query,
          variables,
          workItemId: workItemA.id,
          useRestApi,
        });

        expect(cache.getStored()).toEqual({});
      });
    });

    describe('addWorkItemToColumn', () => {
      it('inserts the work item at the given index', () => {
        const cache = createCache(buildData([workItemA, workItemC]));

        addWorkItemToColumn({
          cache,
          query,
          variables,
          workItem: workItemB,
          index: 1,
          useRestApi,
        });

        expect(getConnection(cache.getStored()).nodes).toEqual([workItemA, workItemB, workItemC]);
      });

      it('does not insert duplicates', () => {
        const cache = createCache(buildData([workItemA, workItemB]));

        addWorkItemToColumn({
          cache,
          query,
          variables,
          workItem: workItemA,
          index: 0,
          useRestApi,
        });

        expect(getConnection(cache.getStored()).nodes).toEqual([workItemA, workItemB]);
      });

      it('runs patchCard on the cloned inserted node', () => {
        const cache = createCache(buildData([workItemA]));
        const patchCard = jest.fn((node) => {
          // eslint-disable-next-line no-param-reassign
          node.title = 'patched';
        });

        addWorkItemToColumn({
          cache,
          query,
          variables,
          workItem: workItemB,
          index: 1,
          patchCard,
          useRestApi,
        });

        expect(patchCard).toHaveBeenCalledTimes(1);
        expect(getConnection(cache.getStored()).nodes[1]).toEqual({
          ...workItemB,
          title: 'patched',
        });
        // The original object is not mutated.
        expect(workItemB.title).toBe('B');
      });

      it('is a no-op when the connection is missing', () => {
        const cache = createCache({});

        addWorkItemToColumn({
          cache,
          query,
          variables,
          workItem: workItemA,
          index: 0,
          useRestApi,
        });

        expect(cache.getStored()).toEqual({});
      });
    });
  });

  // The count-only query is a regular GraphQL query, so its cache entry always
  // lives at namespace.workItems.count regardless of the REST API flag.
  describe('adjustWorkItemCountInColumn', () => {
    it('increments the count by delta', () => {
      const cache = createCache(buildCountData(5));

      adjustWorkItemCountInColumn({ cache, query, variables, delta: 2 });

      expect(cache.getStored().namespace.workItems.count).toBe(7);
    });

    it('clamps the count to zero when delta would drop it below zero', () => {
      const cache = createCache(buildCountData(1));

      adjustWorkItemCountInColumn({ cache, query, variables, delta: -5 });

      expect(cache.getStored().namespace.workItems.count).toBe(0);
    });

    it('is a no-op when count is not a number', () => {
      const cache = createCache(buildCountData());

      adjustWorkItemCountInColumn({ cache, query, variables, delta: 1 });

      expect(cache.getStored().namespace.workItems.count).toBeUndefined();
    });
  });
});
