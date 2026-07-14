import {
  addWorkItemToColumn,
  adjustWorkItemCountInColumn,
  readWorkItemFromColumn,
  readWorkItemsFromColumn,
  removeWorkItemFromColumn,
} from '~/work_items/board/graphql/cache_updates';
import {
  buildBoardWorkItemsResponse,
  buildBoardWorkItemsCountResponse,
  buildWorkItemNode,
  buildStatusWidget,
} from '../mock_data';

// Minimal stand-in for the Apollo cache: the real client strips unselected
// fields (e.g. the STATUS widget) on write, so a fake keeps the helper logic
// under test without coupling to query selections.
const createFakeCache = (data) => {
  let store = data;
  return {
    readQuery: () => store ?? null,
    updateQuery: (_options, updater) => {
      const result = updater(store);
      if (result !== undefined) {
        store = result;
      }
    },
    getStore: () => store,
  };
};

const nodesOf = (cache) => cache.getStore().namespace.workItems.nodes;

describe('work item board cache updates', () => {
  const query = {};
  const variables = {};

  const toDoStatus = {
    __typename: 'WorkItemStatusCustom',
    id: 'gid://gitlab/Status/1',
    name: 'To do',
    iconName: 'status-waiting',
    color: '#737278',
    category: 'TO_DO',
  };

  const buildCacheWith = (nodes) => createFakeCache(buildBoardWorkItemsResponse(nodes).data);

  describe('removeWorkItemFromColumn', () => {
    it('removes the matching node', () => {
      const cache = buildCacheWith([buildWorkItemNode(1), buildWorkItemNode(2)]);

      removeWorkItemFromColumn({
        cache,
        query,
        variables,
        workItemId: 'gid://gitlab/WorkItem/1',
      });

      expect(nodesOf(cache).map((node) => node.id)).toEqual(['gid://gitlab/WorkItem/2']);
    });

    it('does nothing when the cache entry is missing', () => {
      const cache = createFakeCache(undefined);

      expect(() =>
        removeWorkItemFromColumn({
          cache,
          query,
          variables,
          workItemId: 'gid://gitlab/WorkItem/1',
        }),
      ).not.toThrow();
    });
  });

  describe('addWorkItemToColumn', () => {
    it('inserts the node at the given index', () => {
      const cache = buildCacheWith([buildWorkItemNode(1), buildWorkItemNode(2)]);

      addWorkItemToColumn({
        cache,
        query,
        variables,
        workItem: buildWorkItemNode(3),
        index: 1,
      });

      expect(nodesOf(cache).map((node) => node.id)).toEqual([
        'gid://gitlab/WorkItem/1',
        'gid://gitlab/WorkItem/3',
        'gid://gitlab/WorkItem/2',
      ]);
    });

    it('runs patchCard on the inserted node so it matches the target column', () => {
      const cache = buildCacheWith([]);
      const movedNode = buildWorkItemNode(3, {
        widgets: [buildStatusWidget({ ...toDoStatus })],
      });
      const patchCard = (node) => {
        const widget = node.widgets.find((w) => w.type === 'STATUS');
        widget.status = { ...widget.status, name: 'In progress' };
      };

      addWorkItemToColumn({
        cache,
        query,
        variables,
        workItem: movedNode,
        index: 0,
        patchCard,
      });

      const statusWidget = nodesOf(cache)[0].widgets.find((w) => w.type === 'STATUS');
      expect(statusWidget.status.name).toBe('In progress');
    });

    it('does not insert a duplicate when the node is already present', () => {
      const cache = buildCacheWith([buildWorkItemNode(1)]);

      addWorkItemToColumn({
        cache,
        query,
        variables,
        workItem: buildWorkItemNode(1),
        index: 0,
      });

      expect(nodesOf(cache)).toHaveLength(1);
    });

    it('does nothing when the cache entry is missing', () => {
      const cache = createFakeCache(undefined);

      expect(() =>
        addWorkItemToColumn({
          cache,
          query,
          variables,
          workItem: buildWorkItemNode(1),
          index: 0,
        }),
      ).not.toThrow();
    });
  });

  describe('adjustWorkItemCountInColumn', () => {
    const countOf = (cache) => cache.getStore().namespace.workItems.count;

    it('applies the delta to the cached count', () => {
      const cache = createFakeCache(buildBoardWorkItemsCountResponse(5).data);

      adjustWorkItemCountInColumn({ cache, query, variables, delta: -1 });

      expect(countOf(cache)).toBe(4);
    });

    it('does not drop below zero', () => {
      const cache = createFakeCache(buildBoardWorkItemsCountResponse(0).data);

      adjustWorkItemCountInColumn({ cache, query, variables, delta: -1 });

      expect(countOf(cache)).toBe(0);
    });

    it('does nothing when the cache entry is missing', () => {
      const cache = createFakeCache(undefined);

      expect(() =>
        adjustWorkItemCountInColumn({ cache, query, variables, delta: 1 }),
      ).not.toThrow();
    });
  });

  describe('readWorkItemsFromColumn', () => {
    it('returns the column nodes in order', () => {
      const cache = buildCacheWith([buildWorkItemNode(1), buildWorkItemNode(2)]);

      expect(readWorkItemsFromColumn({ cache, query, variables }).map((node) => node.id)).toEqual([
        'gid://gitlab/WorkItem/1',
        'gid://gitlab/WorkItem/2',
      ]);
    });

    it('returns an empty array when the cache entry is missing', () => {
      expect(
        readWorkItemsFromColumn({ cache: createFakeCache(undefined), query, variables }),
      ).toEqual([]);
    });
  });

  describe('readWorkItemFromColumn', () => {
    it('returns a detached clone of the node', () => {
      const node = buildWorkItemNode(1);
      const cache = buildCacheWith([node]);

      const result = readWorkItemFromColumn({
        cache,
        query,
        variables,
        workItemId: 'gid://gitlab/WorkItem/1',
      });

      expect(result).toEqual(node);
      expect(result).not.toBe(node);
    });

    it('returns null when the node or cache entry is missing', () => {
      expect(
        readWorkItemFromColumn({
          cache: createFakeCache(undefined),
          query,
          variables,
          workItemId: 'gid://gitlab/WorkItem/1',
        }),
      ).toBe(null);
    });
  });
});
