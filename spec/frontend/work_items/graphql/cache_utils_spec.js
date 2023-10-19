import { WIDGET_TYPE_HIERARCHY } from '~/work_items/constants';
import { addHierarchyChild, removeHierarchyChild } from '~/work_items/graphql/cache_utils';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

describe('work items graphql cache utils', () => {
  const fullPath = 'full/path';
  const iid = '10';
  const mockCacheData = {
    workspace: {
      workItems: {
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/10',
            title: 'Work item',
            widgets: [
              {
                type: WIDGET_TYPE_HIERARCHY,
                children: {
                  nodes: [
                    {
                      id: 'gid://gitlab/WorkItem/20',
                      title: 'Child',
                    },
                  ],
                },
              },
            ],
          },
        ],
      },
    },
  };

  describe('addHierarchyChild', () => {
    it('updates the work item with a new child', () => {
      const mockCache = {
        readQuery: () => mockCacheData,
        writeQuery: jest.fn(),
      };

      const child = {
        id: 'gid://gitlab/WorkItem/30',
        title: 'New child',
      };

      addHierarchyChild({ cache: mockCache, fullPath, iid, workItem: child });

      expect(mockCache.writeQuery).toHaveBeenCalledWith({
        query: workItemByIidQuery,
        variables: { fullPath, iid },
        data: {
          workspace: {
            workItems: {
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/10',
                  title: 'Work item',
                  widgets: [
                    {
                      type: WIDGET_TYPE_HIERARCHY,
                      children: {
                        nodes: [
                          {
                            id: 'gid://gitlab/WorkItem/20',
                            title: 'Child',
                          },
                          child,
                        ],
                      },
                    },
                  ],
                },
              ],
            },
          },
        },
      });
    });

    it('does not update the work item when there is no cache data', () => {
      const mockCache = {
        readQuery: () => {},
        writeQuery: jest.fn(),
      };

      const child = {
        id: 'gid://gitlab/WorkItem/30',
        title: 'New child',
      };

      addHierarchyChild({ cache: mockCache, fullPath, iid, workItem: child });

      expect(mockCache.writeQuery).not.toHaveBeenCalled();
    });
  });

  describe('removeHierarchyChild', () => {
    it('updates the work item with a new child', () => {
      const mockCache = {
        readQuery: () => mockCacheData,
        writeQuery: jest.fn(),
      };

      const childToRemove = {
        id: 'gid://gitlab/WorkItem/20',
        title: 'Child',
      };

      removeHierarchyChild({ cache: mockCache, fullPath, iid, workItem: childToRemove });

      expect(mockCache.writeQuery).toHaveBeenCalledWith({
        query: workItemByIidQuery,
        variables: { fullPath, iid },
        data: {
          workspace: {
            workItems: {
              nodes: [
                {
                  id: 'gid://gitlab/WorkItem/10',
                  title: 'Work item',
                  widgets: [
                    {
                      type: WIDGET_TYPE_HIERARCHY,
                      children: {
                        nodes: [],
                      },
                    },
                  ],
                },
              ],
            },
          },
        },
      });
    });

    it('does not update the work item when there is no cache data', () => {
      const mockCache = {
        readQuery: () => {},
        writeQuery: jest.fn(),
      };

      const childToRemove = {
        id: 'gid://gitlab/WorkItem/20',
        title: 'Child',
      };

      removeHierarchyChild({ cache: mockCache, fullPath, iid, workItem: childToRemove });

      expect(mockCache.writeQuery).not.toHaveBeenCalled();
    });
  });
});
