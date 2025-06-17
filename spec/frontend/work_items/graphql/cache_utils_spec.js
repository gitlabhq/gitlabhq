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
  mockNewWorkItemIssueCache,
  restoredDraftDataWidgets,
  restoredDraftDataWidgetsForIssue,
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
  // This looks like an odd pattern but is something we do already in several places
  // across our codebase to run tests conditionally, often to quarantine tests.
  // Here we're utilizing it skip test based on feature flag.
  const itif = (condition) => (condition ? it : it.skip);

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
        readQuery: () => mockCacheData,
        writeQuery: jest.fn(),
      };

      addHierarchyChildren({
        cache: mockCache,
        id,
        workItem: workItemHierarchyResponse.data.workspace.workItem,
        childrenIds: [childrenWorkItems[1].id, childrenWorkItems[0].id],
      });

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
                count: 3,
                children: {
                  nodes: [
                    childrenWorkItems[0],
                    {
                      id: 'gid://gitlab/WorkItem/20',
                      title: 'Child',
                    },
                    // closed work item
                    childrenWorkItems[1],
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

      const children = [
        {
          id: 'gid://gitlab/WorkItem/30',
          title: 'New child 1',
        },
        {
          id: 'gid://gitlab/WorkItem/31',
          title: 'New child 3',
        },
      ];

      addHierarchyChildren({ cache: mockCache, id, workItem: children });

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

  describe.each`
    workItemsAlpha
    ${false}
    ${true}
  `(
    'setNewWorkItemCache with feature-flag workItemsAlpha: $workItemsAlpha',
    ({ workItemsAlpha }) => {
      let originalWindowLocation;
      let mockWriteQuery;

      beforeEach(() => {
        originalWindowLocation = window.location;
        delete window.location;
        window.location = new URL('https://gitlab.example.com');
        window.gon.current_user_id = 1;
        window.gon.features = {
          workItemsAlpha,
        };

        mockWriteQuery = jest.fn();
        apolloProvider.clients.defaultClient.cache.writeQuery = mockWriteQuery;

        localStorage.setItem(
          `autosave/new-gitlab-org-epic-draft`,
          JSON.stringify(mockCreateWorkItemDraftData),
        );

        if (window.gon.features.workItemsAlpha) {
          localStorage.setItem(
            `autosave/new-gitlab-org-widgets-draft`,
            JSON.stringify(getWorkItemWidgets(mockCreateWorkItemDraftData)),
          );
        }
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

      itif(workItemsAlpha)('shares widget data between work item types', async () => {
        await setNewWorkItemCache(mockNewWorkItemIssueCache);

        await waitForPromises();

        expect(mockWriteQuery).toHaveBeenCalledWith(
          expect.objectContaining({
            data: expect.objectContaining({
              workspace: expect.objectContaining({
                workItem: expect.objectContaining({
                  // The title was originally set for Epic type in beforeEach call above
                  title: mockCreateWorkItemDraftData.workspace.workItem.title,
                  // The widgets data is shared
                  widgets: expect.arrayContaining(restoredDraftDataWidgetsForIssue),
                }),
              }),
            }),
          }),
        );
      });
    },
  );

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
