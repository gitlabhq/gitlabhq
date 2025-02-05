import { produce } from 'immer';
import VueApollo from 'vue-apollo';
import { map, isEqual } from 'lodash';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { issuesListClient } from '~/issues/list';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { getBaseURL, getParameterByName } from '~/lib/utils/url_utility';
import { convertEachWordToTitleCase } from '~/lib/utils/text_utility';
import { getDraft, clearDraft } from '~/lib/utils/autosave';
import { findWidget } from '~/issues/list/utils';
import {
  findHierarchyWidgets,
  findHierarchyWidgetChildren,
  findNotesWidget,
  getNewWorkItemAutoSaveKey,
  isNotesWidget,
  newWorkItemFullPath,
  newWorkItemId,
} from '../utils';
import {
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_COLOR,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_PARTICIPANTS,
  WIDGET_TYPE_PROGRESS,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WIDGET_TYPE_TIME_TRACKING,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_WEIGHT,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_CRM_CONTACTS,
  NEW_WORK_ITEM_IID,
  WIDGET_TYPE_CURRENT_USER_TODOS,
  WIDGET_TYPE_LINKED_ITEMS,
  STATE_CLOSED,
} from '../constants';
import workItemByIidQuery from './work_item_by_iid.query.graphql';
import workItemByIdQuery from './work_item_by_id.query.graphql';
import getWorkItemTreeQuery from './work_item_tree.query.graphql';

const getNotesWidgetFromSourceData = (draftData) => findNotesWidget(draftData?.workspace?.workItem);

const updateNotesWidgetDataInDraftData = (draftData, notesWidget) => {
  const noteWidgetIndex = draftData.workspace.workItem.widgets.findIndex(isNotesWidget);
  draftData.workspace.workItem.widgets[noteWidgetIndex] = notesWidget;
};

/**
 * Work Item note create subscription update query callback
 *
 * @param currentNotes
 * @param newNote
 */
export const updateCacheAfterCreatingNote = (currentNotes, newNote) => {
  if (!newNote) {
    return currentNotes;
  }

  return produce(currentNotes, (draftData) => {
    const notesWidget = getNotesWidgetFromSourceData(draftData);

    if (!notesWidget.discussions) {
      return;
    }

    const discussion = notesWidget.discussions.nodes.find((d) => d.id === newNote.discussion.id);

    // handle the case where discussion already exists - we don't need to do anything, update will happen automatically
    if (discussion) {
      return;
    }

    notesWidget.discussions.nodes.push(newNote.discussion);
    updateNotesWidgetDataInDraftData(draftData, notesWidget);
  });
};

/**
 * Work Item note delete subscription update query callback
 *
 * @param currentNotes
 * @param subscriptionData
 */
export const updateCacheAfterDeletingNote = (currentNotes, subscriptionData) => {
  if (!subscriptionData.data?.workItemNoteDeleted) {
    return currentNotes;
  }
  const deletedNote = subscriptionData.data.workItemNoteDeleted;
  const { id, discussionId, lastDiscussionNote } = deletedNote;

  return produce(currentNotes, (draftData) => {
    const notesWidget = getNotesWidgetFromSourceData(draftData);

    if (!notesWidget.discussions) {
      return;
    }

    const discussionIndex = notesWidget.discussions.nodes.findIndex(
      (discussion) => discussion.id === discussionId,
    );

    if (discussionIndex === -1) {
      return;
    }

    if (lastDiscussionNote) {
      notesWidget.discussions.nodes.splice(discussionIndex, 1);
    } else {
      const deletedThreadDiscussion = notesWidget.discussions.nodes[discussionIndex];
      const deletedThreadIndex = deletedThreadDiscussion.notes.nodes.findIndex(
        (note) => note.id === id,
      );
      deletedThreadDiscussion.notes.nodes.splice(deletedThreadIndex, 1);
      notesWidget.discussions.nodes[discussionIndex] = deletedThreadDiscussion;
    }

    updateNotesWidgetDataInDraftData(draftData, notesWidget);
  });
};

function updateNoteAwardEmojiCache(currentNotes, note, callback) {
  if (!note.awardEmoji) {
    return currentNotes;
  }
  const { awardEmoji } = note;

  return produce(currentNotes, (draftData) => {
    const notesWidget = getNotesWidgetFromSourceData(draftData);

    if (!notesWidget.discussions) {
      return;
    }

    notesWidget.discussions.nodes.forEach((discussion) => {
      discussion.notes.nodes.forEach((n) => {
        if (n.id === note.id) {
          callback(n, awardEmoji);
        }
      });
    });

    updateNotesWidgetDataInDraftData(draftData, notesWidget);
  });
}

export const updateCacheAfterAddingAwardEmojiToNote = (currentNotes, note) => {
  return updateNoteAwardEmojiCache(currentNotes, note, (n, awardEmoji) => {
    n.awardEmoji.nodes.push(awardEmoji);
  });
};

export const updateCacheAfterRemovingAwardEmojiFromNote = (currentNotes, note) => {
  return updateNoteAwardEmojiCache(currentNotes, note, (n, awardEmoji) => {
    // eslint-disable-next-line no-param-reassign
    n.awardEmoji.nodes = n.awardEmoji.nodes.filter((emoji) => {
      return emoji.name !== awardEmoji.name || emoji.user.id !== awardEmoji.user.id;
    });
  });
};

export const addHierarchyChild = ({ cache, id, workItem, atIndex = null }) => {
  const queryArgs = {
    query: getWorkItemTreeQuery,
    variables: { id },
  };
  const sourceData = cache.readQuery(queryArgs);

  if (!sourceData) {
    return;
  }

  cache.writeQuery({
    ...queryArgs,
    data: produce(sourceData, (draftState) => {
      const widget = findHierarchyWidgets(draftState?.workItem.widgets);
      widget.hasChildren = true;
      const children = findHierarchyWidgetChildren(draftState?.workItem) || [];
      const existingChild = children.find((child) => child.id === workItem?.id);
      if (!existingChild) {
        if (atIndex !== null) {
          children.splice(atIndex, 0, workItem);
        } else {
          children.unshift(workItem);
        }
        widget.hasChildren = children?.length > 0;
        widget.count = children?.length || 0;
      }
    }),
  });
};

export const addHierarchyChildren = ({ cache, id, workItem, childrenIds }) => {
  const queryArgs = {
    query: getWorkItemTreeQuery,
    variables: {
      id,
    },
  };
  const sourceData = cache.readQuery(queryArgs);

  if (!sourceData) {
    return;
  }

  cache.writeQuery({
    ...queryArgs,
    data: produce(sourceData, (draftState) => {
      const widget = findHierarchyWidgets(draftState?.workItem.widgets);
      const newChildren = findHierarchyWidgetChildren(workItem);

      const existingChildren = findHierarchyWidgetChildren(draftState?.workItem);

      const childrenToAdd = newChildren.filter((item) => {
        return childrenIds.includes(item.id);
      });

      for (const item of childrenToAdd) {
        if (item.state === STATE_CLOSED) {
          existingChildren.push(item);
        } else {
          existingChildren.unshift(item);
        }
      }
      widget.hasChildren = childrenToAdd?.length > 0;
      widget.count += childrenToAdd.length;
    }),
  });
};

export const removeHierarchyChild = ({ cache, id, workItem }) => {
  const queryArgs = {
    query: getWorkItemTreeQuery,
    variables: { id },
  };
  const sourceData = cache.readQuery(queryArgs);

  if (!sourceData) {
    return;
  }

  cache.writeQuery({
    ...queryArgs,
    data: produce(sourceData, (draftState) => {
      const widget = findHierarchyWidgets(draftState?.workItem.widgets);
      const children = findHierarchyWidgetChildren(draftState?.workItem);
      const index = children.findIndex((child) => child.id === workItem.id);
      if (index >= 0) children.splice(index, 1);
      widget.hasChildren = children?.length > 0;
      widget.count = children?.length || 0;
    }),
  });
};

export const updateParent = ({ cache, fullPath, iid, workItem }) => {
  const queryArgs = {
    query: workItemByIidQuery,
    variables: { fullPath, iid },
  };
  const sourceData = cache.readQuery(queryArgs);

  if (!sourceData) {
    return;
  }

  cache.writeQuery({
    ...queryArgs,
    data: produce(sourceData, (draftState) => {
      const children = findHierarchyWidgetChildren(draftState.workspace?.workItem);
      const index = children.findIndex((child) => child.id === workItem.id);
      if (index >= 0) children.splice(index, 1);
    }),
  });
};

export const updateWorkItemCurrentTodosWidget = ({ cache, fullPath, iid, todos }) => {
  const query = {
    query: workItemByIidQuery,
    variables: { fullPath, iid },
  };

  const sourceData = cache.readQuery(query);

  if (!sourceData) {
    return;
  }

  const newData = produce(sourceData, (draftState) => {
    const { widgets } = draftState.workspace.workItem;
    const widgetCurrentUserTodos = widgets.find(
      (widget) => widget.type === WIDGET_TYPE_CURRENT_USER_TODOS,
    );

    widgetCurrentUserTodos.currentUserTodos.nodes = todos;
  });

  cache.writeQuery({ ...query, data: newData });
};

export const setNewWorkItemCache = async (
  fullPath,
  widgetDefinitions,
  workItemType,
  workItemTypeId,
  workItemTypeIconName,
  workItemTitle = '',
  workItemDescription = '',
  // eslint-disable-next-line max-params
) => {
  const workItemAttributesWrapperOrder = [
    WIDGET_TYPE_ASSIGNEES,
    WIDGET_TYPE_LABELS,
    WIDGET_TYPE_WEIGHT,
    WIDGET_TYPE_MILESTONE,
    WIDGET_TYPE_ITERATION,
    WIDGET_TYPE_START_AND_DUE_DATE,
    WIDGET_TYPE_PROGRESS,
    WIDGET_TYPE_HEALTH_STATUS,
    WIDGET_TYPE_LINKED_ITEMS,
    WIDGET_TYPE_COLOR,
    WIDGET_TYPE_HIERARCHY,
    WIDGET_TYPE_TIME_TRACKING,
    WIDGET_TYPE_PARTICIPANTS,
    WIDGET_TYPE_CRM_CONTACTS,
  ];

  if (!widgetDefinitions) {
    return;
  }

  const workItemTitleCase = convertEachWordToTitleCase(workItemType.split('_').join(' '));
  const availableWidgets = widgetDefinitions?.flatMap((i) => i.type) || [];
  const currentUserId = convertToGraphQLId(TYPENAME_USER, gon?.current_user_id);
  const baseURL = getBaseURL();

  const widgets = [];

  const autosaveKey = getNewWorkItemAutoSaveKey(fullPath, workItemType);
  const getStorageDraftString = getDraft(autosaveKey);
  const draftData = JSON.parse(getDraft(autosaveKey));

  const draftTitle = draftData?.workspace?.workItem?.title || '';
  const draftDescriptionWidget =
    findWidget(WIDGET_TYPE_DESCRIPTION, draftData?.workspace?.workItem) || {};
  const draftDescription = draftDescriptionWidget?.description || null;
  const isWorkItemToResolveDiscussion = getParameterByName(
    'merge_request_to_resolve_discussions_of',
  );

  widgets.push({
    type: WIDGET_TYPE_DESCRIPTION,
    description: isWorkItemToResolveDiscussion ? workItemDescription : draftDescription,
    descriptionHtml: '',
    lastEditedAt: null,
    lastEditedBy: null,
    taskCompletionStatus: null,
    __typename: 'WorkItemWidgetDescription',
  });

  workItemAttributesWrapperOrder.forEach((widgetName) => {
    if (availableWidgets.includes(widgetName)) {
      if (widgetName === WIDGET_TYPE_ASSIGNEES) {
        const assigneesWidgetData = widgetDefinitions.find(
          (definition) => definition.type === WIDGET_TYPE_ASSIGNEES,
        );
        widgets.push({
          type: 'ASSIGNEES',
          allowsMultipleAssignees: assigneesWidgetData.allowsMultipleAssignees || false,
          canInviteMembers: assigneesWidgetData.canInviteMembers || false,
          assignees: {
            nodes: [],
            __typename: 'UserCoreConnection',
          },
          __typename: 'WorkItemWidgetAssignees',
        });
      }

      if (widgetName === WIDGET_TYPE_LINKED_ITEMS) {
        widgets.push({
          type: WIDGET_TYPE_LINKED_ITEMS,
          linkedItems: {
            nodes: [],
          },
          __typename: 'WorkItemWidgetLinkedItems',
        });
      }

      if (widgetName === WIDGET_TYPE_CRM_CONTACTS) {
        widgets.push({
          type: 'CRM_CONTACTS',
          contacts: {
            nodes: [],
            __typename: 'CustomerRelationsContactConnection',
          },
          __typename: 'WorkItemWidgetCrmContacts',
        });
      }

      if (widgetName === WIDGET_TYPE_LABELS) {
        const labelsWidgetData = widgetDefinitions.find(
          (definition) => definition.type === WIDGET_TYPE_LABELS,
        );
        widgets.push({
          type: 'LABELS',
          allowsScopedLabels: labelsWidgetData.allowsScopedLabels,
          labels: {
            nodes: [],
            __typename: 'LabelConnection',
          },
          __typename: 'WorkItemWidgetLabels',
        });
      }

      if (widgetName === WIDGET_TYPE_WEIGHT) {
        const weightWidgetData = widgetDefinitions.find(
          (definition) => definition.type === WIDGET_TYPE_WEIGHT,
        );

        widgets.push({
          type: 'WEIGHT',
          weight: null,
          rolledUpWeight: 0,
          rolledUpCompletedWeight: 0,
          widgetDefinition: {
            editable: weightWidgetData?.editable,
            rollUp: weightWidgetData?.rollUp,
          },
          __typename: 'WorkItemWidgetWeight',
        });
      }

      if (widgetName === WIDGET_TYPE_MILESTONE) {
        widgets.push({
          type: 'MILESTONE',
          milestone: null,
          __typename: 'WorkItemWidgetMilestone',
        });
      }

      if (widgetName === WIDGET_TYPE_ITERATION) {
        widgets.push({
          iteration: null,
          type: 'ITERATION',
          __typename: 'WorkItemWidgetIteration',
        });
      }

      if (widgetName === WIDGET_TYPE_START_AND_DUE_DATE) {
        widgets.push({
          type: 'START_AND_DUE_DATE',
          dueDate: null,
          startDate: null,
          isFixed: false,
          rollUp: false,
          __typename: 'WorkItemWidgetStartAndDueDate',
        });
      }

      if (widgetName === WIDGET_TYPE_PROGRESS) {
        widgets.push({
          type: 'PROGRESS',
          progress: null,
          updatedAt: null,
          __typename: 'WorkItemWidgetProgress',
        });
      }

      if (widgetName === WIDGET_TYPE_HEALTH_STATUS) {
        widgets.push({
          type: 'HEALTH_STATUS',
          healthStatus: null,
          rolledUpHealthStatus: [],
          __typename: 'WorkItemWidgetHealthStatus',
        });
      }

      if (widgetName === WIDGET_TYPE_COLOR) {
        widgets.push({
          type: 'COLOR',
          color: '#1068bf',
          textColor: '#FFFFFF',
          __typename: 'WorkItemWidgetColor',
        });
      }

      if (widgetName === WIDGET_TYPE_HIERARCHY) {
        widgets.push({
          type: 'HIERARCHY',
          hasChildren: false,
          hasParent: false,
          parent: null,
          depthLimitReachedByType: [],
          rolledUpCountsByType: [],
          children: {
            nodes: [],
            __typename: 'WorkItemConnection',
          },
          __typename: 'WorkItemWidgetHierarchy',
        });
      }

      if (widgetName === WIDGET_TYPE_TIME_TRACKING) {
        widgets.push({
          type: 'TIME_TRACKING',
          timeEstimate: 0,
          timelogs: {
            nodes: [],
            __typename: 'WorkItemTimelogConnection',
          },
          totalTimeSpent: 0,
          __typename: 'WorkItemWidgetTimeTracking',
        });
      }
    }
  });

  const issuesListApolloProvider = new VueApollo({
    defaultClient: await issuesListClient(),
  });

  const cacheProvider = document.querySelector('.js-issues-list-app')
    ? issuesListApolloProvider
    : apolloProvider;

  const newWorkItemPath = newWorkItemFullPath(fullPath, workItemType);

  // get the widgets stored in draft data
  const draftDataWidgetTypes = map(draftData?.workspace?.workItem?.widgets, 'type') || [];
  const freshWidgetTypes = map(widgets, 'type') || [];

  // this is to fix errors when we are introducing a new widget and the cache always updates from the old widgets
  // Like if we we introduce a new widget , the user might always see the cached data until hits cancel
  const draftWidgetsAreSameAsCacheDigits = isEqual(
    draftDataWidgetTypes.sort(),
    freshWidgetTypes.sort(),
  );

  const isValidDraftData =
    draftData?.workspace?.workItem &&
    getStorageDraftString &&
    draftData?.workspace?.workItem &&
    draftWidgetsAreSameAsCacheDigits;

  /** check in case of someone plays with the localstorage, we need to be sure */
  if (!isValidDraftData) {
    clearDraft(autosaveKey);
  }

  cacheProvider.clients.defaultClient.cache.writeQuery({
    query: workItemByIidQuery,
    variables: {
      fullPath: newWorkItemPath,
      iid: NEW_WORK_ITEM_IID,
    },
    data: {
      workspace: {
        id: newWorkItemPath,
        workItem: {
          id: newWorkItemId(workItemType),
          iid: NEW_WORK_ITEM_IID,
          archived: false,
          title: isWorkItemToResolveDiscussion ? workItemTitle : draftTitle,
          state: 'OPEN',
          description: null,
          confidential: false,
          createdAt: null,
          updatedAt: null,
          closedAt: null,
          webUrl: `${baseURL}/groups/gitlab-org/-/work_items/new`,
          reference: '',
          createNoteEmail: null,
          project: null,
          namespace: {
            id: newWorkItemPath,
            fullPath,
            name: newWorkItemPath,
            fullName: newWorkItemPath,
            __typename: 'Namespace',
          },
          author: {
            id: currentUserId,
            avatarUrl: gon?.current_user_avatar_url,
            username: gon?.current_username,
            name: gon?.current_user_fullname,
            webUrl: `${baseURL}/${gon?.current_username}`,
            webPath: `/${gon?.current_username}`,
            __typename: 'UserCore',
          },
          workItemType: {
            id: workItemTypeId || 'mock-work-item-type-id',
            name: workItemTitleCase,
            iconName: workItemTypeIconName,
            __typename: 'WorkItemType',
          },
          userPermissions: {
            deleteWorkItem: true,
            updateWorkItem: true,
            adminParentLink: true,
            setWorkItemMetadata: true,
            createNote: true,
            adminWorkItemLink: true,
            markNoteAsInternal: true,
            reportSpam: true,
            __typename: 'WorkItemPermissions',
          },
          widgets,
          __typename: 'WorkItem',
        },
        __typename: 'Namespace',
      },
    },
  });
};

export const optimisticUserPermissions = {
  deleteWorkItem: false,
  updateWorkItem: false,
  adminParentLink: false,
  setWorkItemMetadata: false,
  createNote: false,
  adminWorkItemLink: false,
  markNoteAsInternal: false,
  reportSpam: false,
  __typename: 'WorkItemPermissions',
};

export const updateCountsForParent = ({ cache, parentId, workItemType, isClosing }) => {
  if (!parentId) {
    return null;
  }

  const parent = cache.readQuery({
    query: workItemByIdQuery,
    variables: {
      id: parentId,
    },
  });

  if (!parent) {
    return null;
  }

  const updatedParent = produce(parent, (draft) => {
    const hierarchyWidget = findHierarchyWidgets(draft.workItem.widgets);

    const counts = hierarchyWidget.rolledUpCountsByType.find(
      (i) => i.workItemType.name === workItemType,
    );

    if (isClosing) {
      counts.countsByState.closed += 1;
      counts.countsByState.opened -= 1;
    } else {
      counts.countsByState.closed -= 1;
      counts.countsByState.opened += 1;
    }
  });

  cache.writeQuery({
    query: workItemByIdQuery,
    variables: {
      id: parentId,
    },
    data: updatedParent,
  });

  return updatedParent;
};
