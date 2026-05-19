import { cloneDeep } from 'lodash-es';
import { WIDGET_TYPE_HIERARCHY, WIDGET_TYPE_STATUS, STATE_CLOSED } from '~/work_items/constants';
import {
  addHierarchyChild,
  removeHierarchyChild,
  addHierarchyChildren,
  setNewWorkItemCache,
  getNewWorkItemSharedCache,
  legacyGetNewWorkItemSharedCache,
  updateCacheAfterCreatingNote,
  updateCountsForParent,
} from '~/work_items/graphql/cache_utils';
import {
  findHierarchyWidget,
  findNotesWidget,
  getWorkItemWidgets,
  getNewWorkItemWidgetsAutoSaveKey,
} from '~/work_items/utils';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import workItemLinkedItemsSlimQuery from '~/work_items/graphql/work_items_linked_items_slim.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { linkedItems } from '~/graphql_shared/issuable_client_state';
import {
  childrenWorkItems,
  createWorkItemNoteResponse,
  mockWorkItemNotesByIidResponse,
  workItemResponseFactory,
  mockCreateWorkItemDraftData,
  mockNewWorkItemCache,
  restoredDraftDataWidgets,
  restoredDraftDataWidgetsEmpty,
} from '../mock_data';

describe('work items graphql cache utils', () => {
  const originalFeatures = window.gon.features;
  const id = 'gid://gitlab/WorkItem/10';
  const mockCacheData = {
    workItem: {
      id: 'gid://gitlab/WorkItem/10',
      title: 'Work item',
      widgets: [
        {
          type: WIDGET_TYPE_HIERARCHY,
          hasChildren: true,
          count: 1,
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
  };

  beforeEach(() => {
    window.gon.features = {};
  });

  afterAll(() => {
    window.gon.features = originalFeatures;
  });

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

      addHierarchyChild({ cache: mockCache, id, workItem: child });

      expect(mockCache.writeQuery).toHaveBeenCalledWith({
        query: getWorkItemTreeQuery,
        variables: { id },
        data: {
          workItem: {
            id: 'gid://gitlab/WorkItem/10',
            title: 'Work item',
            widgets: [
              {
                type: WIDGET_TYPE_HIERARCHY,
                hasChildren: true,
                count: 2,
                children: {
                  nodes: [
                    child,
                    {
                      id: 'gid://gitlab/WorkItem/20',
                      title: 'Child',
                    },
                  ],
                },
              },
            ],
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

      addHierarchyChild({ cache: mockCache, id, workItem: child });

      expect(mockCache.writeQuery).not.toHaveBeenCalled();
    });
  });

  describe('addHierarchyChildren', () => {
    it('updates the work item with new children', () => {
      const mockCache = {
        identify: jest.fn().mockReturnValue(`WorkItem:${id}`),
        modify: jest.fn(),
      };

      addHierarchyChildren({
        cache: mockCache,
        id,
        newChildren: [childrenWorkItems[1], childrenWorkItems[0]],
      });

      const { fields } = mockCache.modify.mock.calls[0][0];
      const result = fields.widgets([
        {
          __typename: 'WorkItemWidgetHierarchy',
          type: 'HIERARCHY',
          children: {
            nodes: [{ __typename: 'WorkItem', id: 'gid://gitlab/WorkItem/99', state: 'OPEN' }],
          },
          count: 1,
          hasChildren: true,
        },
      ]);

      const updated = result.find((w) => w.type === 'HIERARCHY');

      expect(updated).toEqual(
        expect.objectContaining({
          __typename: 'WorkItemWidgetHierarchy',
          children: expect.objectContaining({
            nodes: expect.arrayContaining([
              expect.objectContaining({ id: childrenWorkItems[0].id }),
              expect.objectContaining({ id: 'gid://gitlab/WorkItem/99' }),
              expect.objectContaining({ id: childrenWorkItems[1].id }),
            ]),
          }),
          hasChildren: true,
          count: 3,
        }),
      );

      // Optional: ensure open children come before closed ones
      const openIndex = updated.children.nodes.findIndex((n) => n.state !== STATE_CLOSED);
      const closedIndex = updated.children.nodes.findIndex((n) => n.state === STATE_CLOSED);
      if (closedIndex !== -1) expect(openIndex).toBeLessThan(closedIndex);
    });

    it('does not update the work item when there is no cache data', () => {
      const mockCache = {
        identify: jest.fn().mockReturnValue(undefined), // simulate missing cache entity
        modify: jest.fn(),
      };

      // Should not throw
      expect(() =>
        addHierarchyChildren({
          cache: mockCache,
          id,
          newChildren: [childrenWorkItems[1], childrenWorkItems[0]],
        }),
      ).not.toThrow();

      // Should not modify cache at all
      expect(mockCache.modify).not.toHaveBeenCalled();
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

      removeHierarchyChild({ cache: mockCache, id, workItem: childToRemove });

      expect(mockCache.writeQuery).toHaveBeenCalledWith({
        query: getWorkItemTreeQuery,
        variables: { id },
        data: {
          workItem: {
            id: 'gid://gitlab/WorkItem/10',
            title: 'Work item',
            widgets: [
              {
                type: WIDGET_TYPE_HIERARCHY,
                hasChildren: false,
                count: 0,
                children: {
                  nodes: [],
                },
              },
            ],
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

      removeHierarchyChild({ cache: mockCache, id, workItem: childToRemove });

      expect(mockCache.writeQuery).not.toHaveBeenCalled();
    });
  });

  describe('setNewWorkItemCache', () => {
    let originalWindowLocation;
    let mockWriteQuery;

    beforeEach(() => {
      originalWindowLocation = window.location;
      delete window.location;
      window.location = new URL('https://gitlab.example.com');
      window.gon.current_user_id = 1;

      mockWriteQuery = jest.fn();
      apolloProvider.clients.defaultClient.cache.writeQuery = mockWriteQuery;

      localStorage.setItem(
        `autosave/new-gitlab-org-list-route-epic-draft`,
        JSON.stringify(mockCreateWorkItemDraftData),
      );

      localStorage.setItem(
        `autosave/new-gitlab-org-list-route-widgets-draft`,
        JSON.stringify(getWorkItemWidgets(mockCreateWorkItemDraftData)),
      );
    });

    afterEach(() => {
      window.location = originalWindowLocation;
    });

    it('updates cache from localstorage to save cache data', async () => {
      window.location.search = '';
      await setNewWorkItemCache(mockNewWorkItemCache);
      await waitForPromises();

      expect(mockWriteQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            namespace: expect.objectContaining({
              workItem: expect.objectContaining({
                title: mockCreateWorkItemDraftData.namespace.workItem.title,
                widgets: expect.arrayContaining(restoredDraftDataWidgets),
              }),
            }),
          }),
        }),
      );
    });

    it.each`
      description                         | locationSearchString          | expectedTitle                                           | expectedWidgets
      ${'restores cache with empty form'} | ${'?vulnerability_id=1'}      | ${''}                                                   | ${restoredDraftDataWidgetsEmpty}
      ${'restores cache with empty form'} | ${'?discussion_to_resolve=1'} | ${''}                                                   | ${restoredDraftDataWidgetsEmpty}
      ${'restores cache with draft'}      | ${'?type=ISSUE'}              | ${mockCreateWorkItemDraftData.namespace.workItem.title} | ${restoredDraftDataWidgets}
    `(
      '$description when URL params include $locationSearchString',
      async ({ locationSearchString, expectedTitle, expectedWidgets }) => {
        window.location.search = locationSearchString;
        await setNewWorkItemCache(mockNewWorkItemCache);
        await waitForPromises();

        expect(mockWriteQuery).toHaveBeenCalledWith(
          expect.objectContaining({
            data: expect.objectContaining({
              namespace: expect.objectContaining({
                workItem: expect.objectContaining({
                  title: expectedTitle,
                  widgets: expect.arrayContaining(expectedWidgets),
                }),
              }),
            }),
          }),
        );
      },
    );
  });

  describe('statuses for getNewWorkItemSharedCache', () => {
    const fullPath = 'gitlab-org';
    const context = 'list-route';

    const allowedStatus1 = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
      category: 'to_do',
      name: 'To do',
      iconName: 'status-waiting',
      color: '#737278',
      __typename: 'WorkItemStatus',
    };
    const allowedStatus2 = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/2',
      category: 'in_progress',
      name: 'In progress',
      iconName: 'status-running',
      color: '#1f75cb',
      __typename: 'WorkItemStatus',
    };
    const disallowedStatus = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/99',
      category: 'done',
      name: 'Done',
      iconName: 'status-success',
      color: '#108548',
      __typename: 'WorkItemStatus',
    };

    const buildWidgetDefinitions = (overrides = {}) => [
      {
        __typename: 'WorkItemWidgetDefinitionStatus',
        type: WIDGET_TYPE_STATUS,
        allowedStatuses: [allowedStatus1, allowedStatus2],
        defaultOpenStatus: allowedStatus1,
        ...overrides,
      },
    ];

    const callGetNewWorkItemSharedCache = (widgetDefinitions) =>
      getNewWorkItemSharedCache({
        fullPath,
        context,
        workItemType: 'Issue',
        relatedItemId: null,
        isValidWorkItemDescription: false,
        workItemDescription: '',
        widgetDefinitions,
      });

    const setCachedStatus = (status) => {
      const widgetsKey = `autosave/${getNewWorkItemWidgetsAutoSaveKey({ fullPath, context, relatedItemId: null })}`;
      localStorage.setItem(widgetsKey, JSON.stringify({ [WIDGET_TYPE_STATUS]: { status } }));
    };

    beforeEach(() => {
      localStorage.clear();
    });

    it('uses defaultOpenStatus when there is no cached status', () => {
      const { features } = callGetNewWorkItemSharedCache(buildWidgetDefinitions());

      expect(features.status.status).toEqual(allowedStatus1);
    });

    it('uses cached status when it exists in allowedStatuses', () => {
      setCachedStatus(allowedStatus2);

      const { features } = callGetNewWorkItemSharedCache(buildWidgetDefinitions());

      expect(features.status.status).toEqual(allowedStatus2);
    });

    it('falls back to defaultOpenStatus when cached status is not in allowedStatuses', () => {
      setCachedStatus(disallowedStatus);

      const { features } = callGetNewWorkItemSharedCache(buildWidgetDefinitions());

      expect(features.status.status).toEqual(allowedStatus1);
    });
  });

  describe('statuses for legacyGetNewWorkItemSharedCache', () => {
    const fullPath = 'gitlab-org';
    const context = 'list-route';

    const allowedStatus1 = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
      category: 'to_do',
      name: 'To do',
      iconName: 'status-waiting',
      color: '#737278',
      __typename: 'WorkItemStatus',
    };
    const allowedStatus2 = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/2',
      category: 'in_progress',
      name: 'In progress',
      iconName: 'status-running',
      color: '#1f75cb',
      __typename: 'WorkItemStatus',
    };
    const disallowedStatus = {
      id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/99',
      category: 'done',
      name: 'Done',
      iconName: 'status-success',
      color: '#108548',
      __typename: 'WorkItemStatus',
    };

    const widgetDefinitions = [
      {
        __typename: 'WorkItemWidgetDefinitionStatus',
        type: WIDGET_TYPE_STATUS,
        allowedStatuses: [allowedStatus1, allowedStatus2],
        defaultOpenStatus: allowedStatus1,
      },
    ];

    const setCachedStatus = (status) => {
      const widgetsKey = `autosave/${getNewWorkItemWidgetsAutoSaveKey({ fullPath, context, relatedItemId: null })}`;
      localStorage.setItem(widgetsKey, JSON.stringify({ [WIDGET_TYPE_STATUS]: { status } }));
    };

    const buildLegacyCache = () =>
      legacyGetNewWorkItemSharedCache({
        workItemAttributesWrapperOrder: [WIDGET_TYPE_STATUS],
        widgetDefinitions,
        fullPath,
        context,
        workItemType: 'Issue',
        relatedItemId: null,
        isValidWorkItemDescription: false,
        workItemDescription: '',
      });

    const findStatusWidget = (widgets) => widgets.find((w) => w.type === WIDGET_TYPE_STATUS);

    beforeEach(() => {
      localStorage.clear();
    });

    it('uses defaultOpenStatus when there is no cached status', () => {
      const { widgets } = buildLegacyCache();

      expect(findStatusWidget(widgets).status).toEqual(allowedStatus1);
    });

    it('uses cached status when it exists in allowedStatuses', () => {
      setCachedStatus(allowedStatus2);

      const { widgets } = buildLegacyCache();

      expect(findStatusWidget(widgets).status).toEqual(allowedStatus2);
    });

    it('falls back to defaultOpenStatus when cached status is not in allowedStatuses', () => {
      setCachedStatus(disallowedStatus);

      const { widgets } = buildLegacyCache();

      expect(findStatusWidget(widgets).status).toEqual(allowedStatus1);
    });
  });

  describe('updateCacheAfterCreatingNote', () => {
    const findDiscussions = ({ namespace }) =>
      findNotesWidget(namespace.workItem).discussions.nodes;

    it('adds a new discussion to the notes widget', () => {
      const currentNotes = mockWorkItemNotesByIidResponse.data;
      const newNote = createWorkItemNoteResponse().data.createNote.note;

      expect(findDiscussions(currentNotes)).toHaveLength(3);

      const updatedNotes = updateCacheAfterCreatingNote(currentNotes, newNote);

      expect(findDiscussions(updatedNotes)).toHaveLength(4);
      expect(findDiscussions(updatedNotes).at(-1)).toBe(newNote.discussion);
    });

    it('adds a new discussion at the top when prepend is true', () => {
      const currentNotes = mockWorkItemNotesByIidResponse.data;
      const newNote = createWorkItemNoteResponse().data.createNote.note;

      expect(findDiscussions(currentNotes)).toHaveLength(3);

      const updatedNotes = updateCacheAfterCreatingNote(currentNotes, newNote, { prepend: true });

      expect(findDiscussions(updatedNotes)).toHaveLength(4);
      expect(findDiscussions(updatedNotes).at(0)).toBe(newNote.discussion);
    });

    it('does not modify notes widget when newNote is undefined', () => {
      const currentNotes = mockWorkItemNotesByIidResponse.data;
      const newNote = undefined;

      expect(findDiscussions(currentNotes)).toHaveLength(3);

      const updatedNotes = updateCacheAfterCreatingNote(currentNotes, newNote);

      expect(findDiscussions(updatedNotes)).toHaveLength(3);
    });

    it('does not add duplicate discussions', () => {
      const currentNotes = cloneDeep(mockWorkItemNotesByIidResponse.data);
      const newNote = createWorkItemNoteResponse().data.createNote.note;
      findDiscussions(currentNotes).push(newNote.discussion);

      expect(findDiscussions(currentNotes)).toHaveLength(4);

      const updatedNotes = updateCacheAfterCreatingNote(currentNotes, newNote);

      expect(findDiscussions(updatedNotes)).toHaveLength(4);
    });
  });

  describe('updateCountsForParent', () => {
    const mockWorkItemData = workItemResponseFactory();
    const mockCache = {
      readQuery: () => mockWorkItemData.data,
      writeQuery: jest.fn(),
    };
    const workItemType = 'Task';

    const getCounts = (data) =>
      findHierarchyWidget(data.workItem).rolledUpCountsByType.find(
        (i) => i.workItemType.name === workItemType,
      );

    it('updates the cache with new parent data', () => {
      const updatedParent = updateCountsForParent({
        cache: mockCache,
        parentId: mockWorkItemData.data.workItem.id,
        workItemType,
        isClosing: true,
      });

      expect(mockCache.writeQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          data: updatedParent,
        }),
      );
    });

    it('increases closed count and decreases opened count when closing', () => {
      const updatedParent = updateCountsForParent({
        cache: mockCache,
        parentId: mockWorkItemData.data.workItem.id,
        workItemType,
        isClosing: true,
      });

      const oldCounts = getCounts(mockWorkItemData.data);
      const newCounts = getCounts(updatedParent);

      expect(newCounts.countsByState.opened).toBeLessThan(oldCounts.countsByState.opened);
      expect(newCounts.countsByState.closed).toBeGreaterThan(oldCounts.countsByState.closed);
    });

    it('decreases closed count and increases opened count when reopening', () => {
      const updatedParent = updateCountsForParent({
        cache: mockCache,
        parentId: mockWorkItemData.data.workItem.id,
        workItemType,
        isClosing: false,
      });

      const oldCounts = getCounts(mockWorkItemData.data);
      const newCounts = getCounts(updatedParent);

      expect(newCounts.countsByState.opened).toBeGreaterThan(oldCounts.countsByState.opened);
      expect(newCounts.countsByState.closed).toBeLessThan(oldCounts.countsByState.closed);
    });
  });

  describe('linkedItems reactive variable in widgets merge', () => {
    const fullPath = 'gitlab-org';
    const iid = '1';
    const { cache } = apolloProvider.clients.defaultClient;
    const originalWriteQuery = cache.writeQuery.bind(cache);
    const originalExtract = cache.extract.bind(cache);
    const key = `${fullPath}:${iid}`;

    const mockLinkedItem = (itemId) => ({
      __typename: 'LinkedWorkItemType',
      linkId: `gid://gitlab/WorkItems::RelatedWorkItemLink/${itemId}`,
      linkType: 'relates_to',
      workItemState: 'OPEN',
      workItem: {
        __typename: 'WorkItem',
        id: `gid://gitlab/WorkItem/${itemId}`,
        iid: `${itemId}`,
        confidential: false,
        namespace: { __typename: 'Namespace', id: 'gid://gitlab/Group/1', fullPath },
        workItemType: {
          __typename: 'WorkItemType',
          id: 'gid://gitlab/WorkItems::Type/8',
          name: 'Epic',
          iconName: 'work-item-epic',
        },
        title: `Item ${itemId}`,
        state: 'OPEN',
        createdAt: '2025-01-01T00:00:00Z',
        closedAt: null,
        webUrl: `https://example.com/${itemId}`,
        reference: `${fullPath}#${itemId}`,
      },
    });

    const write = (nodes) => {
      cache.writeQuery({
        query: workItemLinkedItemsSlimQuery,
        variables: { fullPath, iid },
        data: {
          namespace: {
            __typename: 'Namespace',
            id: 'gid://gitlab/Group/1',
            workItem: {
              __typename: 'WorkItem',
              id: 'gid://gitlab/WorkItem/1',
              widgets: [
                {
                  __typename: 'WorkItemWidgetLinkedItems',
                  type: 'LINKED_ITEMS',
                  blockedByCount: 0,
                  blockingCount: 0,
                  linkedItems: { __typename: 'LinkedWorkItemTypeConnection', nodes },
                },
              ],
            },
          },
        },
      });
    };

    // `setNewWorkItemCache` tests replace cache.writeQuery with a mock,
    // so we restore the original to ensure write() works correctly.
    beforeEach(() => {
      cache.writeQuery = originalWriteQuery;
      cache.restore({});
      linkedItems({});
    });

    it.each`
      description                                                                   | writeNodes                                        | evictKey                               | expectedItems
      ${'populates linkedItems with resolvable items when some are not yet cached'} | ${() => [mockLinkedItem(10), mockLinkedItem(99)]} | ${'WorkItem:gid://gitlab/WorkItem/99'} | ${[{ iid: '10', title: 'Item 10' }]}
      ${'skips items not yet resolvable in cache without silently failing'}         | ${() => [mockLinkedItem(10)]}                     | ${'WorkItem:gid://gitlab/WorkItem/10'} | ${[]}
    `('$description', ({ writeNodes, evictKey, expectedItems }) => {
      write([mockLinkedItem(10)]);

      const spy = jest.spyOn(cache, 'extract');
      spy.mockImplementation(() => {
        const data = originalExtract();
        delete data[evictKey];
        return data;
      });

      try {
        expect(() => write(writeNodes())).not.toThrow();
      } finally {
        spy.mockRestore();
      }

      expect(linkedItems()[key]).toMatchObject(expectedItems);
    });
  });
});
