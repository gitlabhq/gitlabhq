import { cloneDeep } from 'lodash';
import { WIDGET_TYPE_HIERARCHY } from '~/work_items/constants';
import {
  addHierarchyChild,
  removeHierarchyChild,
  addHierarchyChildren,
  setNewWorkItemCache,
  updateCacheAfterCreatingNote,
  updateCountsForParent,
} from '~/work_items/graphql/cache_utils';
import { findHierarchyWidget, findNotesWidget, getWorkItemWidgets } from '~/work_items/utils';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import {
  childrenWorkItems,
  createWorkItemNoteResponse,
  mockWorkItemNotesByIidResponse,
  workItemHierarchyResponse,
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
        workItem: workItemHierarchyResponse.data.workspace.workItem,
        childrenIds: [childrenWorkItems[1].id, childrenWorkItems[0].id],
      });

      const { fields } = mockCache.modify.mock.calls[0][0];
      const result = fields.widgets(
        [
          {
            __typename: 'WorkItemWidgetHierarchy',
            children: { nodes: [{ __typename: 'WorkItem', id: 'gid://gitlab/WorkItem/99' }] },
            count: 1,
            hasChildren: true,
          },
        ],
        {
          readField: (field, ref) => {
            // eslint-disable-next-line no-underscore-dangle
            if (field === '__typename') return ref.__typename;
            if (field === 'children') return ref.children;
            if (field === 'count') return ref.count;
            if (field === 'hasChildren') return ref.hasChildren;
            return undefined;
          },
          toReference: (obj) => obj,
        },
      );

      expect(result[0]).toEqual(
        expect.objectContaining({
          __typename: 'WorkItemWidgetHierarchy',
          hasChildren: true,
          count: 3,
          children: expect.objectContaining({
            nodes: expect.arrayContaining([
              expect.objectContaining({ id: childrenWorkItems[0].id }),
              expect.objectContaining({ id: 'gid://gitlab/WorkItem/99' }),
              expect.objectContaining({ id: childrenWorkItems[1].id }),
            ]),
          }),
        }),
      );
    });

    it('does not update the work item when there is no cache data', () => {
      const mockCache = {
        identify: jest.fn().mockReturnValue(`WorkItem:${id}`),
        modify: jest.fn(),
      };

      const workItem = {
        id: 'gid://gitlab/WorkItem/10',
        widgets: [{ __typename: 'WorkItemWidgetHierarchy' }],
      };

      addHierarchyChildren({
        cache: mockCache,
        id,
        workItem,
        childrenIds: [],
      });

      const { fields } = mockCache.modify.mock.calls[0][0];
      const result = fields.widgets([{ __typename: 'WorkItemWidgetHierarchy' }], {
        readField: (field) => {
          if (field === 'count') return 0;
          if (field === 'children') return { nodes: [] };
          if (field === 'hasChildren') return false;
          if (field === '__typename') return 'WorkItemWidgetHierarchy';
          return undefined;
        },
        toReference: () => null,
      });

      expect(result[0].children?.nodes ?? []).toHaveLength(0);
      expect(result[0].count).toBe(0);
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
            workspace: expect.objectContaining({
              workItem: expect.objectContaining({
                title: mockCreateWorkItemDraftData.workspace.workItem.title,
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
      ${'restores cache with draft'}      | ${'?type=ISSUE'}              | ${mockCreateWorkItemDraftData.workspace.workItem.title} | ${restoredDraftDataWidgets}
    `(
      '$description when URL params include $locationSearchString',
      async ({ locationSearchString, expectedTitle, expectedWidgets }) => {
        window.location.search = locationSearchString;
        await setNewWorkItemCache(mockNewWorkItemCache);
        await waitForPromises();

        expect(mockWriteQuery).toHaveBeenCalledWith(
          expect.objectContaining({
            data: expect.objectContaining({
              workspace: expect.objectContaining({
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

  describe('updateCacheAfterCreatingNote', () => {
    const findDiscussions = ({ workspace }) =>
      findNotesWidget(workspace.workItem).discussions.nodes;

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
});
