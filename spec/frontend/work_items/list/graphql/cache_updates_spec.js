import { InMemoryCache } from '@apollo/client/core';
import possibleTypes from '~/graphql_shared/possible_types.json';
import { typePolicies } from '~/lib/graphql';
import hasWorkItemsQuery from '~/work_items/list/graphql/has_work_items.query.graphql';
import {
  evictNamespaceWorkItems,
  evictWorkItem,
  groupWorkItemChanges,
  isWorkItemCached,
  mergeWorkItemChangeAction,
} from '~/work_items/list/graphql/cache_updates';

const NAMESPACE_ID = 'gid://gitlab/Group/3';
const workItemId = (id) => `gid://gitlab/WorkItem/${id}`;

// Stand-in for the Apollo cache, so the eviction helpers can be asserted on the arguments they
// build without depending on any query selections.
const createFakeCache = () => ({
  identify: ({ __typename, id }) => `${__typename}:${id}`,
  evict: jest.fn(),
  gc: jest.fn(),
  readFragment: jest.fn(),
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
