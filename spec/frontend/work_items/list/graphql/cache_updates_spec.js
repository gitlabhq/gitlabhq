import { InMemoryCache } from '@apollo/client/core';
import possibleTypes from '~/graphql_shared/possible_types.json';
import { typePolicies } from '~/lib/graphql';
import hasWorkItemsQuery from '~/work_items/list/graphql/has_work_items.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import {
  evictNamespaceWorkItems,
  evictWorkItem,
  groupWorkItemChanges,
  isWorkItemCached,
  mergeWorkItemChangeAction,
  findMatchingWorkItems,
  dropMatchCacheEntries,
  MAX_MATCH_IDS,
} from '~/work_items/list/graphql/cache_updates';
import { buildWorkItemNode, buildBoardWorkItemsResponse, mockGroupId } from '../../board/mock_data';

const NAMESPACE_ID = 'gid://gitlab/Group/3';
const workItemId = (id) => `gid://gitlab/WorkItem/${id}`;

// Stand-in for the Apollo cache, so the eviction helpers can be asserted on the arguments they
// build without depending on any query selections.
const createFakeCache = () => ({
  identify: ({ __typename, id }) => `${__typename}:${id}`,
  evict: jest.fn(),
  gc: jest.fn(),
  readFragment: jest.fn(),
  modify: jest.fn(),
});

describe('work item list cache updates', () => {
  describe('evictNamespaceWorkItems', () => {
    it('evicts the whole workItems field on the namespace and collects garbage', () => {
      const cache = createFakeCache();

      evictNamespaceWorkItems(cache, NAMESPACE_ID);

      expect(cache.evict).toHaveBeenCalledWith({
        id: 'Namespace:gid://gitlab/Group/3',
        fieldName: 'workItems',
      });
      expect(cache.gc).toHaveBeenCalledTimes(1);
    });

    it('also evicts the top-level restWorkItems field when useRestApi is true', () => {
      const cache = createFakeCache();

      evictNamespaceWorkItems(cache, NAMESPACE_ID, { useRestApi: true });

      expect(cache.evict).toHaveBeenCalledWith({ fieldName: 'restWorkItems' });
    });

    it('leaves restWorkItems alone when useRestApi is false', () => {
      const cache = createFakeCache();

      evictNamespaceWorkItems(cache, NAMESPACE_ID);

      expect(cache.evict).not.toHaveBeenCalledWith({ fieldName: 'restWorkItems' });
    });
  });

  describe('evictWorkItem', () => {
    it('evicts the work item entity', () => {
      const cache = createFakeCache();

      evictWorkItem(cache, workItemId(1));

      expect(cache.evict).toHaveBeenCalledWith({ id: 'WorkItem:gid://gitlab/WorkItem/1' });
    });

    it('leaves garbage collection to the caller, so a batch can be evicted first', () => {
      const cache = createFakeCache();

      evictWorkItem(cache, workItemId(1));

      expect(cache.gc).not.toHaveBeenCalled();
    });

    // The helper relies on Apollo filtering dangling references out of list fields when reading,
    // which only a real cache can demonstrate.
    describe('with a real cache', () => {
      const variables = { fullPath: 'group/path' };

      const cacheWithWorkItems = (ids) => {
        const cache = new InMemoryCache({ possibleTypes, typePolicies });
        cache.writeQuery({
          query: hasWorkItemsQuery,
          variables,
          data: {
            namespace: {
              __typename: 'Group',
              id: NAMESPACE_ID,
              workItems: {
                __typename: 'WorkItemConnection',
                nodes: ids.map((id) => ({ __typename: 'WorkItem', id: workItemId(id) })),
              },
            },
          },
        });
        return cache;
      };

      const nodesIn = (cache) =>
        cache.readQuery({ query: hasWorkItemsQuery, variables }).namespace.workItems.nodes;

      it('removes the work item from a cached connection', () => {
        const cache = cacheWithWorkItems([1, 2]);

        evictWorkItem(cache, workItemId(1));

        expect(nodesIn(cache)).toEqual([{ __typename: 'WorkItem', id: workItemId(2) }]);
      });

      it('leaves other work items in place', () => {
        const cache = cacheWithWorkItems([1, 2]);

        evictWorkItem(cache, workItemId(3));

        expect(nodesIn(cache)).toHaveLength(2);
      });
    });
  });

  describe('isWorkItemCached', () => {
    it('is true when the work item is normalised in the cache', () => {
      const cache = createFakeCache();
      cache.readFragment.mockReturnValue({ id: workItemId(1) });

      expect(isWorkItemCached(cache, workItemId(1))).toBe(true);
      expect(cache.readFragment).toHaveBeenCalledWith(
        expect.objectContaining({ id: 'WorkItem:gid://gitlab/WorkItem/1' }),
      );
    });

    it('is false when the work item is not in the cache', () => {
      const cache = createFakeCache();
      cache.readFragment.mockReturnValue(null);

      expect(isWorkItemCached(cache, workItemId(1))).toBe(false);
    });
  });

  describe('findMatchingWorkItems', () => {
    const queryVariables = { fullPath: 'group/path', sort: 'CREATED_DESC' };
    const createFakeClient = (data) => ({ query: jest.fn().mockResolvedValue({ data }) });

    it('returns null without querying when there are too many ids to ask the server about', async () => {
      const client = createFakeClient({});
      const ids = Array.from({ length: MAX_MATCH_IDS + 1 }, (_, i) => workItemId(i));

      const result = await findMatchingWorkItems({
        client,
        queryVariables,
        ids,
        useRestApi: false,
        isBoardView: false,
        glFeatures: {},
      });

      expect(result).toBeNull();
      expect(client.query).not.toHaveBeenCalled();
    });

    it('checks the slim list query, replacing pagination with the candidate ids', async () => {
      const client = createFakeClient({ namespace: { workItems: { nodes: [] } } });

      await findMatchingWorkItems({
        client,
        queryVariables: { ...queryVariables, afterCursor: 'cursor', firstPageSize: 20 },
        ids: [workItemId(1), workItemId(2)],
        useRestApi: false,
        isBoardView: false,
        glFeatures: {},
      });

      expect(client.query).toHaveBeenCalledWith({
        query: getWorkItemsSlimQuery,
        variables: {
          ...queryVariables,
          ids: [workItemId(1), workItemId(2)],
          afterCursor: null,
          beforeCursor: null,
          firstPageSize: 2,
          lastPageSize: null,
        },
        fetchPolicy: 'network-only',
        context: { featureCategory: 'portfolio_management' },
      });
    });

    it('checks the REST query when useRestApi is true', async () => {
      const client = createFakeClient({ restWorkItems: { nodes: [] } });

      await findMatchingWorkItems({
        client,
        queryVariables,
        ids: [workItemId(1)],
        useRestApi: true,
        isBoardView: false,
        glFeatures: {},
      });

      expect(client.query).toHaveBeenCalledWith(
        expect.objectContaining({ query: getWorkItemsRestQuery }),
      );
    });

    it('checks the board query in board view', async () => {
      const client = createFakeClient({ namespace: { workItems: { nodes: [] } } });

      await findMatchingWorkItems({
        client,
        queryVariables,
        ids: [workItemId(1)],
        useRestApi: false,
        isBoardView: true,
        glFeatures: {},
      });

      expect(client.query).toHaveBeenCalledWith(
        expect.objectContaining({ query: getBoardWorkItemsQuery }),
      );
    });

    it('checks the REST query in board view when the REST flag is on', async () => {
      const client = createFakeClient({ restWorkItems: { nodes: [] } });

      await findMatchingWorkItems({
        client,
        queryVariables,
        ids: [workItemId(1)],
        useRestApi: true,
        isBoardView: true,
        glFeatures: { workItemRestApiFrontendUsers: true },
      });

      expect(client.query).toHaveBeenCalledWith(
        expect.objectContaining({ query: getWorkItemsRestQuery }),
      );
    });

    it('returns the ids the server matched', async () => {
      const client = createFakeClient({
        namespace: { workItems: { nodes: [{ id: workItemId(2) }] } },
      });

      const result = await findMatchingWorkItems({
        client,
        queryVariables,
        ids: [workItemId(1), workItemId(2)],
        useRestApi: false,
        isBoardView: false,
        glFeatures: {},
      });

      expect(result).toEqual(new Set([workItemId(2)]));
    });

    it('returns an empty set when nothing matches', async () => {
      const client = createFakeClient({ namespace: { workItems: { nodes: [] } } });

      const result = await findMatchingWorkItems({
        client,
        queryVariables,
        ids: [workItemId(1)],
        useRestApi: false,
        isBoardView: false,
        glFeatures: {},
      });

      expect(result).toEqual(new Set());
    });
  });

  describe('dropMatchCacheEntries', () => {
    it('strips the ids-keyed workItems entry on the namespace', () => {
      const cache = createFakeCache();

      dropMatchCacheEntries(cache, NAMESPACE_ID);

      expect(cache.modify).toHaveBeenCalledWith({
        id: 'Namespace:gid://gitlab/Group/3',
        fields: { workItems: expect.any(Function) },
      });
    });

    it('also strips the ids-keyed restWorkItems entry at the root', () => {
      const cache = createFakeCache();

      dropMatchCacheEntries(cache, NAMESPACE_ID);

      expect(cache.modify).toHaveBeenCalledWith({
        fields: { restWorkItems: expect.any(Function) },
      });
    });

    it('skips the namespace-scoped call when there is no namespace id yet', () => {
      const cache = createFakeCache();

      dropMatchCacheEntries(cache, null);

      expect(cache.modify).toHaveBeenCalledTimes(1);
      expect(cache.modify).toHaveBeenCalledWith({
        fields: { restWorkItems: expect.any(Function) },
      });
    });

    it('collects garbage after stripping entries', () => {
      const cache = createFakeCache();

      dropMatchCacheEntries(cache, NAMESPACE_ID);

      expect(cache.gc).toHaveBeenCalledTimes(1);
    });

    it('deletes only the store field the match query created', () => {
      const cache = createFakeCache();
      const DELETE = Symbol('DELETE');

      dropMatchCacheEntries(cache, NAMESPACE_ID);
      const { workItems: stripMatchEntry } = cache.modify.mock.calls[0][0].fields;

      expect(
        stripMatchEntry('existing', { storeFieldName: 'workItems({"ids":["1"]})', DELETE }),
      ).toBe(DELETE);
      expect(
        stripMatchEntry('existing', { storeFieldName: 'workItems({"state":"OPENED"})', DELETE }),
      ).toBe('existing');
    });

    // Confirms the real Apollo store field name actually contains `"ids":` for a match call, which
    // is the assumption the field modifier above relies on.
    describe('with a real cache', () => {
      it('removes only the store field the match query created', () => {
        const cache = new InMemoryCache({ possibleTypes, typePolicies });
        const variables = { fullPath: 'group/path', sort: 'CREATED_DESC' };
        // `namespace(fullPath:)` resolves to the concrete `Namespace` type (not `Group`), which is
        // what `TYPENAME_NAMESPACE` normalizes the entity under.
        const write = (vars, nodes) => {
          const { namespace } = buildBoardWorkItemsResponse(nodes).data;
          return cache.writeQuery({
            query: getWorkItemsSlimQuery,
            variables: vars,
            data: { namespace: { ...namespace, __typename: 'Namespace' } },
          });
        };

        write(variables, [buildWorkItemNode(1)]);
        write({ ...variables, ids: [workItemId(2)], firstPageSize: 1 }, [buildWorkItemNode(2)]);

        dropMatchCacheEntries(cache, mockGroupId);

        const workItemsFields = Object.keys(cache.extract()[`Namespace:${mockGroupId}`]).filter(
          (key) => key.startsWith('workItems('),
        );
        expect(workItemsFields).toHaveLength(1);
        expect(workItemsFields[0]).not.toContain('"ids"');
      });
    });
  });

  describe('mergeWorkItemChangeAction', () => {
    it.each`
      existing     | incoming     | expected
      ${undefined} | ${'UPDATED'} | ${'UPDATED'}
      ${undefined} | ${'CREATED'} | ${'CREATED'}
      ${undefined} | ${'DELETED'} | ${'DELETED'}
      ${'UPDATED'} | ${'CREATED'} | ${'CREATED'}
      ${'CREATED'} | ${'UPDATED'} | ${'CREATED'}
      ${'CREATED'} | ${'DELETED'} | ${'DELETED'}
      ${'DELETED'} | ${'CREATED'} | ${'DELETED'}
      ${'DELETED'} | ${'UPDATED'} | ${'DELETED'}
      ${'UPDATED'} | ${'UPDATED'} | ${'UPDATED'}
    `('merges $existing and $incoming into $expected', ({ existing, incoming, expected }) => {
      expect(mergeWorkItemChangeAction(existing, incoming)).toBe(expected);
    });
  });

  describe('groupWorkItemChanges', () => {
    it('groups ids by action', () => {
      const changes = new Map([
        [workItemId(1), 'CREATED'],
        [workItemId(2), 'UPDATED'],
        [workItemId(3), 'DELETED'],
        [workItemId(4), 'UPDATED'],
      ]);

      expect(groupWorkItemChanges(changes)).toEqual({
        created: [workItemId(1)],
        updated: [workItemId(2), workItemId(4)],
        deleted: [workItemId(3)],
      });
    });

    it('returns empty groups for no changes', () => {
      expect(groupWorkItemChanges(new Map())).toEqual({ created: [], updated: [], deleted: [] });
    });

    it('treats an unrecognised action as an update, so it is not silently dropped', () => {
      const changes = new Map([[workItemId(1), 'MOVED']]);

      expect(groupWorkItemChanges(changes)).toEqual({
        created: [],
        updated: [workItemId(1)],
        deleted: [],
      });
    });
  });
});
