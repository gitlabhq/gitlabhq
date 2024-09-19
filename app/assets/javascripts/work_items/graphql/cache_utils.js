import { produce } from 'immer';
import VueApollo from 'vue-apollo';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { issuesListClient } from '~/issues/list';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { getBaseURL } from '~/lib/utils/url_utility';
import { convertEachWordToTitleCase } from '~/lib/utils/text_utility';
import {
  findHierarchyWidgets,
  findHierarchyWidgetChildren,
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
  WIDGET_TYPE_ROLLEDUP_DATES,
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
} from '../constants';
import workItemByIidQuery from './work_item_by_iid.query.graphql';
import getWorkItemTreeQuery from './work_item_tree.query.graphql';

const getNotesWidgetFromSourceData = (draftData) =>
  draftData?.workspace?.workItem?.widgets.find(isNotesWidget);

const updateNotesWidgetDataInDraftData = (draftData, notesWidget) => {
  const noteWidgetIndex = draftData.workspace.workItem.widgets.findIndex(isNotesWidget);
  draftData.workspace.workItem.widgets[noteWidgetIndex] = notesWidget;
};

/**
 * Work Item note create subscription update query callback
 *
 * @param currentNotes
 * @param subscriptionData
 */
export const updateCacheAfterCreatingNote = (currentNotes, subscriptionData) => {
  if (!subscriptionData.data?.workItemNoteCreated) {
    return currentNotes;
  }
  const newNote = subscriptionData.data.workItemNoteCreated;

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

export const addHierarchyChildren = ({ cache, id, workItem, newItemsToAddCount }) => {
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
      const newChildren = findHierarchyWidgetChildren(workItem);

      const existingChildren = findHierarchyWidgetChildren(draftState?.workItem);

      const childrenToAdd = newChildren.slice(0, newItemsToAddCount);

      for (const item of childrenToAdd) {
        if (item) {
          existingChildren.unshift(item);
        }
      }
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

export const setNewWorkItemCache = async (
  fullPath,
  widgetDefinitions,
  workItemType,
  workItemTypeId,
  // eslint-disable-next-line max-params
) => {
  const workItemAttributesWrapperOrder = [
    WIDGET_TYPE_ASSIGNEES,
    WIDGET_TYPE_LABELS,
    WIDGET_TYPE_WEIGHT,
    WIDGET_TYPE_ROLLEDUP_DATES,
    WIDGET_TYPE_MILESTONE,
    WIDGET_TYPE_ITERATION,
    WIDGET_TYPE_START_AND_DUE_DATE,
    WIDGET_TYPE_PROGRESS,
    WIDGET_TYPE_HEALTH_STATUS,
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
  const availableWidgets = widgetDefinitions?.flatMap((i) => i.type);
  const currentUserId = convertToGraphQLId(TYPENAME_USER, gon?.current_user_id);
  const baseURL = getBaseURL();

  const widgets = [];

  widgets.push({
    type: WIDGET_TYPE_DESCRIPTION,
    description: null,
    descriptionHtml: '',
    lastEditedAt: null,
    lastEditedBy: null,
    taskCompletionStatus: null,
    __typename: 'WorkItemWidgetDescription',
  });

  widgets.push({
    type: WIDGET_TYPE_PARTICIPANTS,
    participants: {
      nodes: [
        {
          id: currentUserId,
          avatarUrl: gon?.current_user_avatar_url,
          username: gon?.current_username,
          name: gon?.current_user_fullname,
          webUrl: `${baseURL}/${gon?.current_username}`,
          webPath: `/${gon?.current_username}`,
          __typename: 'UserCore',
        },
      ],
      __typename: 'UserCoreConnection',
    },
    __typename: 'WorkItemWidgetParticipants',
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

      if (widgetName === WIDGET_TYPE_ROLLEDUP_DATES) {
        widgets.push({
          type: 'ROLLEDUP_DATES',
          dueDate: null,
          dueDateFixed: null,
          dueDateIsFixed: null,
          startDate: null,
          startDateFixed: null,
          startDateIsFixed: null,
          __typename: 'WorkItemWidgetRolledupDates',
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
          title: '',
          state: 'OPEN',
          description: null,
          confidential: false,
          createdAt: null,
          updatedAt: null,
          closedAt: null,
          webUrl: `${baseURL}/groups/gitlab-org/-/work_items/new`,
          reference: '',
          createNoteEmail: null,
          namespace: {
            id: newWorkItemPath,
            fullPath,
            name: newWorkItemPath,
            __typename: 'Namespace', // eslint-disable-line @gitlab/require-i18n-strings
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
            iconName: 'issue-type-epic',
            __typename: 'WorkItemType',
          },
          userPermissions: {
            deleteWorkItem: true,
            updateWorkItem: true,
            adminParentLink: true,
            setWorkItemMetadata: true,
            createNote: true,
            adminWorkItemLink: true,
            __typename: 'WorkItemPermissions',
          },
          widgets,
          __typename: 'WorkItem',
        },
        __typename: 'Namespace', // eslint-disable-line @gitlab/require-i18n-strings
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
  __typename: 'WorkItemPermissions',
};
