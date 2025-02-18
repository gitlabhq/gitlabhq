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
import { findHierarchyWidgets, findNotesWidget } from '~/work_items/utils';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import {
  childrenWorkItems,
  createWorkItemNoteResponse,
  mockWorkItemNotesByIidResponse,
  workItemHierarchyResponse,
  workItemResponseFactory,
} from '../mock_data';

describe('work items graphql cache utils', () => {
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

  describe('setNewWorkItemCache', () => {
    it('updates cache from localstorage to save cache data', async () => {
      const mockWriteQuery = jest.fn();

      apolloProvider.clients.defaultClient.cache.writeQuery = mockWriteQuery;
      window.gon.current_user_id = 1;

      const draftData = {
        workspace: {
          __typename: 'Namespace',
          id: 'gitlab-org-epic-id',
          workItem: {
            __typename: 'WorkItem',
            id: 'gid://gitlab/WorkItem/new-epic',
            iid: 'new-work-item-iid',
            archived: false,
            title: 'ssss',
            state: 'OPEN',
            description: null,
            confidential: false,
            createdAt: null,
            closedAt: null,
            webUrl: 'http://127.0.0.1:3000/groups/gitlab-org/-/work_items/new',
            reference: '',
            createNoteEmail: null,
            namespace: {
              __typename: 'Namespace',
              id: 'gitlab-org-epic-id',
              fullPath: 'gitlab-org',
              name: 'gitlab-org-epic-id',
            },
            author: {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/1',
              avatarUrl:
                'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
              name: 'Administrator',
              username: 'root',
              webUrl: 'http://127.0.0.1:3000/root',
              webPath: '/root',
            },
            workItemType: {
              __typename: 'WorkItemType',
              id: 'gid://gitlab/WorkItems::Type/8',
              name: 'Epic',
              iconName: 'issue-type-epic',
            },
            userPermissions: {
              __typename: 'WorkItemPermissions',
              deleteWorkItem: true,
              updateWorkItem: true,
              adminParentLink: true,
              setWorkItemMetadata: true,
              createNote: true,
              adminWorkItemLink: true,
              markNoteAsInternal: true,
            },
            widgets: [
              {
                __typename: 'WorkItemWidgetDescription',
                type: 'DESCRIPTION',
                description: '',
                descriptionHtml: '',
                lastEditedAt: null,
                lastEditedBy: null,
                taskCompletionStatus: null,
              },
              {
                __typename: 'WorkItemWidgetLabels',
                type: 'LABELS',
                allowsScopedLabels: true,
                labels: {
                  __typename: 'LabelConnection',
                  nodes: [
                    {
                      __typename: 'Label',
                      id: 'gid://gitlab/GroupLabel/12',
                      title: 'Brische',
                      description: null,
                      color: '#472821',
                      textColor: '#FFFFFF',
                    },
                  ],
                },
              },
              {
                __typename: 'WorkItemWidgetWeight',
                type: 'WEIGHT',
                weight: null,
                rolledUpWeight: 0,
                rolledUpCompletedWeight: 0,
                widgetDefinition: { editable: false, rollUp: true },
              },
              {
                __typename: 'WorkItemWidgetStartAndDueDate',
                type: 'START_AND_DUE_DATE',
                dueDate: null,
                startDate: null,
                rollUp: false,
                isFixed: false,
              },
              {
                __typename: 'WorkItemWidgetHealthStatus',
                type: 'HEALTH_STATUS',
                healthStatus: null,
                rolledUpHealthStatus: [],
              },
              {
                __typename: 'WorkItemWidgetLinkedItems',
                type: 'LINKED_ITEMS',
                linkedItems: { nodes: [] },
              },
              {
                __typename: 'WorkItemWidgetColor',
                type: 'COLOR',
                color: '#1068bf',
                textColor: '#FFFFFF',
              },
              {
                __typename: 'WorkItemWidgetHierarchy',
                type: 'HIERARCHY',
                hasChildren: false,
                hasParent: false,
                rolledUpCountsByType: [],
                parent: null,
              },
              {
                __typename: 'WorkItemWidgetTimeTracking',
                type: 'TIME_TRACKING',
                timeEstimate: 0,
                timelogs: { __typename: 'WorkItemTimelogConnection', nodes: [] },
                totalTimeSpent: 0,
              },
            ],
          },
        },
      };

      localStorage.setItem(`autosave/new-gitlab-org-epic-draft`, JSON.stringify(draftData));

      await setNewWorkItemCache(
        'gitlab-org',
        [
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'AWARD_EMOJI',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'COLOR',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'CURRENT_USER_TODOS',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'DESCRIPTION',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'HEALTH_STATUS',
          },
          {
            __typename: 'WorkItemWidgetDefinitionHierarchy',
            type: 'HIERARCHY',
            allowedChildTypes: {
              __typename: 'WorkItemTypeConnection',
              nodes: [
                {
                  __typename: 'WorkItemType',
                  id: 'gid://gitlab/WorkItems::Type/8',
                  name: 'Epic',
                },
                {
                  __typename: 'WorkItemType',
                  id: 'gid://gitlab/WorkItems::Type/1',
                  name: 'Issue',
                },
              ],
            },
          },
          {
            __typename: 'WorkItemWidgetDefinitionLabels',
            type: 'LABELS',
            allowsScopedLabels: true,
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'LINKED_ITEMS',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'NOTES',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'NOTIFICATIONS',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'PARTICIPANTS',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'START_AND_DUE_DATE',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'STATUS',
          },
          {
            __typename: 'WorkItemWidgetDefinitionGeneric',
            type: 'TIME_TRACKING',
          },
          {
            __typename: 'WorkItemWidgetDefinitionWeight',
            type: 'WEIGHT',
            editable: false,
            rollUp: true,
          },
        ],
        'EPIC',
        'gid://gitlab/WorkItems::Type/8 ',
        'issue-type-epic',
      );

      await waitForPromises();

      expect(mockWriteQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            workspace: expect.objectContaining({
              workItem: expect.objectContaining({
                title: draftData.workspace.workItem.title,
              }),
            }),
          }),
        }),
      );
    });
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
      findHierarchyWidgets(data.workItem.widgets).rolledUpCountsByType.find(
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
