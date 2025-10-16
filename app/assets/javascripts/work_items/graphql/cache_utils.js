import { produce } from 'immer';
import { map, isEqual } from 'lodash';
import { getApolloProvider } from '~/issues/list/issue_client';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { getBaseURL } from '~/lib/utils/url_utility';
import { convertEachWordToTitleCase } from '~/lib/utils/text_utility';
import { getDraft, clearDraft } from '~/lib/utils/autosave';
import {
  newWorkItemOptimisticUserPermissions,
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
  WIDGET_TYPE_LINKED_ITEMS,
  STATE_CLOSED,
  WIDGET_TYPE_CUSTOM_FIELDS,
  WIDGET_TYPE_STATUS,
} from 'ee_else_ce/work_items/constants';
import {
  findCurrentUserTodosWidget,
  findHierarchyWidget,
  findHierarchyWidgetChildren,
  findNotesWidget,
  getNewWorkItemAutoSaveKey,
  getNewWorkItemWidgetsAutoSaveKey,
  isNotesWidget,
  newWorkItemFullPath,
  newWorkItemId,
  getWorkItemWidgets,
} from '../utils';
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
export const updateCacheAfterCreatingNote = (currentNotes, newNote, { prepend = false } = {}) => {
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

    if (prepend) {
      notesWidget.discussions.nodes.unshift(newNote.discussion);
    } else {
      notesWidget.discussions.nodes.push(newNote.discussion);
    }

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
    if (
      !n.awardEmoji.nodes.some(
        (emoji) => emoji.name === awardEmoji.name && emoji.user.id === awardEmoji.user.id,
      )
    ) {
      n.awardEmoji.nodes.push(awardEmoji);
    }
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
      const widget = findHierarchyWidget(draftState?.workItem);
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
  const newChildren = findHierarchyWidgetChildren(workItem);

  cache.modify({
    id: cache.identify({ __typename: 'WorkItem', id }),
    fields: {
      widgets(existingWidgets = [], { readField, toReference }) {
        return existingWidgets.map((widgetRef) => {
          if (readField('__typename', widgetRef) !== 'WorkItemWidgetHierarchy') {
            return widgetRef;
          }

          const existingChildrenConnection = readField('children', widgetRef) || {};
          const existingNodes = existingChildrenConnection.nodes || [];

          const childrenToAdd = newChildren.filter((child) => childrenIds.includes(child.id));

          const openRefs = [];
          const closedRefs = [];

          for (const child of childrenToAdd) {
            // eslint-disable-next-line no-underscore-dangle
            const ref = toReference({ __typename: child.__typename || 'WorkItem', id: child.id });
            // eslint-disable-next-line no-continue
            if (!ref) continue;
            (child.state === STATE_CLOSED ? closedRefs : openRefs).push(ref);
          }

          const mergedNodes = [...openRefs, ...existingNodes, ...closedRefs];

          return {
            ...widgetRef,
            children: { ...existingChildrenConnection, nodes: mergedNodes },
            hasChildren: readField('hasChildren', widgetRef) || mergedNodes.length > 0,
            count: (readField('count', widgetRef) || 0) + childrenToAdd.length,
          };
        });
      },
    },
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
      const widget = findHierarchyWidget(draftState?.workItem);
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
    const widgetCurrentUserTodos = findCurrentUserTodosWidget(draftState.workspace.workItem);
    widgetCurrentUserTodos.currentUserTodos.nodes = todos;
  });

  cache.writeQuery({ ...query, data: newData });
};

export const getNewWorkItemSharedCache = ({
  workItemAttributesWrapperOrder,
  widgetDefinitions,
  fullPath,
  context,
  workItemType,
  relatedItemId,
  isValidWorkItemDescription,
  workItemDescription = '',
}) => {
  const widgetsAutosaveKey = getNewWorkItemWidgetsAutoSaveKey({ fullPath, context, relatedItemId });
  const fullDraftAutosaveKey = getNewWorkItemAutoSaveKey({
    fullPath,
    context,
    workItemType,
    relatedItemId,
  });
  const workItemTypeSpecificWidgets =
    getWorkItemWidgets(JSON.parse(getDraft(fullDraftAutosaveKey))) || {};
  const sharedCacheWidgets = JSON.parse(getDraft(widgetsAutosaveKey)) || {};

  const availableWidgets = widgetDefinitions?.flatMap((i) => i.type) || [];
  const draftTitle = sharedCacheWidgets.TITLE || '';
  const draftDescription = sharedCacheWidgets[WIDGET_TYPE_DESCRIPTION]?.description || null;
  const widgets = [];

  widgets.push({
    type: WIDGET_TYPE_DESCRIPTION,
    description: isValidWorkItemDescription ? workItemDescription : draftDescription,
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
            nodes: sharedCacheWidgets[WIDGET_TYPE_ASSIGNEES]
              ? sharedCacheWidgets[WIDGET_TYPE_ASSIGNEES]?.assignees.nodes || []
              : [],
            __typename: 'UserCoreConnection',
          },
          __typename: 'WorkItemWidgetAssignees',
        });
      }

      if (widgetName === WIDGET_TYPE_LINKED_ITEMS) {
        widgets.push({
          type: WIDGET_TYPE_LINKED_ITEMS,
          blockingCount: 0,
          blockedByCount: 0,
          linkedItems: {
            nodes: [],
          },
          __typename: 'WorkItemWidgetLinkedItems',
        });
      }

      if (widgetName === WIDGET_TYPE_CRM_CONTACTS) {
        widgets.push({
          type: 'CRM_CONTACTS',
          contactsAvailable: false,
          contacts: {
            nodes: sharedCacheWidgets[WIDGET_TYPE_CRM_CONTACTS]
              ? sharedCacheWidgets[WIDGET_TYPE_CRM_CONTACTS]?.contacts.nodes || []
              : [],
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
            nodes: sharedCacheWidgets[WIDGET_TYPE_LABELS]
              ? sharedCacheWidgets[WIDGET_TYPE_LABELS]?.labels.nodes || []
              : [],
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
          weight: sharedCacheWidgets[WIDGET_TYPE_WEIGHT]
            ? sharedCacheWidgets[WIDGET_TYPE_WEIGHT]?.weight || null
            : null,
          rolledUpWeight: null,
          rolledUpCompletedWeight: null,
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
          milestone: sharedCacheWidgets[WIDGET_TYPE_MILESTONE]
            ? sharedCacheWidgets[WIDGET_TYPE_MILESTONE]?.milestone || null
            : null,
          projectMilestone: false,
          __typename: 'WorkItemWidgetMilestone',
        });
      }

      if (widgetName === WIDGET_TYPE_ITERATION) {
        widgets.push({
          iteration: sharedCacheWidgets[WIDGET_TYPE_ITERATION]
            ? sharedCacheWidgets[WIDGET_TYPE_ITERATION]?.iteration || null
            : null,
          type: 'ITERATION',
          __typename: 'WorkItemWidgetIteration',
        });
      }

      if (widgetName === WIDGET_TYPE_START_AND_DUE_DATE) {
        const startDueDateDraft = sharedCacheWidgets[WIDGET_TYPE_START_AND_DUE_DATE] || {};

        widgets.push({
          type: 'START_AND_DUE_DATE',
          dueDate: startDueDateDraft?.dueDate || null,
          startDate: startDueDateDraft?.startDate || null,
          isFixed: startDueDateDraft?.isFixed || false,
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
          healthStatus: sharedCacheWidgets[WIDGET_TYPE_HEALTH_STATUS]
            ? sharedCacheWidgets[WIDGET_TYPE_HEALTH_STATUS]?.healthStatus || null
            : null,
          rolledUpHealthStatus: [],
          __typename: 'WorkItemWidgetHealthStatus',
        });
      }

      if (widgetName === WIDGET_TYPE_COLOR) {
        widgets.push({
          type: 'COLOR',
          color: sharedCacheWidgets[WIDGET_TYPE_COLOR]
            ? sharedCacheWidgets[WIDGET_TYPE_COLOR]?.color || '#1068bf'
            : '#1068bf',
          textColor: '#FFFFFF',
          __typename: 'WorkItemWidgetColor',
        });
      }

      if (widgetName === WIDGET_TYPE_STATUS) {
        const { defaultOpenStatus } = widgetDefinitions.find(
          (widget) => widget.type === WIDGET_TYPE_STATUS,
        );
        widgets.push({
          type: 'STATUS',
          status: sharedCacheWidgets[WIDGET_TYPE_STATUS]
            ? sharedCacheWidgets[WIDGET_TYPE_STATUS]?.status || defaultOpenStatus
            : defaultOpenStatus,
          __typename: 'WorkItemWidgetStatus',
        });
      }

      if (widgetName === WIDGET_TYPE_HIERARCHY) {
        // Get parent value from shared widget localStorage entry.
        const cachedParent = sharedCacheWidgets[WIDGET_TYPE_HIERARCHY]?.parent || null;
        // Get parent value from type-specific localStorage entry.
        const typeSpecificParent =
          workItemTypeSpecificWidgets[WIDGET_TYPE_HIERARCHY]?.parent || null;

        // Set fallback parent value
        let parent = workItemTypeSpecificWidgets[WIDGET_TYPE_HIERARCHY] ? typeSpecificParent : null;

        if (cachedParent) {
          // Set parent from cached parent only if it is compatible
          // with current work item type, fall back to type-specific parent otherwise.
          const allowedParentTypes =
            widgetDefinitions.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)
              ?.allowedParentTypes?.nodes || [];

          parent = allowedParentTypes.some((type) => type.id === cachedParent.workItemType.id)
            ? cachedParent
            : typeSpecificParent;
        }

        widgets.push({
          type: 'HIERARCHY',
          hasChildren: false,
          hasParent: false,
          parent,
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
          humanReadableAttributes: {
            timeEstimate: '',
          },
          timelogs: {
            nodes: [],
            __typename: 'WorkItemTimelogConnection',
          },
          totalTimeSpent: 0,
          __typename: 'WorkItemWidgetTimeTracking',
        });
      }

      if (widgetName === WIDGET_TYPE_CUSTOM_FIELDS) {
        // Get available custom fields for this work item type
        const customFieldsWidgetData = widgetDefinitions.find(
          (definition) => definition.type === WIDGET_TYPE_CUSTOM_FIELDS,
        );
        const availableCustomFieldValues = customFieldsWidgetData.customFieldValues;
        // Get custom fields with set values from shared widget localStorage entry.
        const cachedCustomFieldValues =
          sharedCacheWidgets[WIDGET_TYPE_CUSTOM_FIELDS]?.customFieldValues;
        // Get custom fields with set values from type-specific localStorage entry.
        const typeSpecificCustomFieldValues =
          workItemTypeSpecificWidgets[WIDGET_TYPE_CUSTOM_FIELDS]?.customFieldValues || [];

        // Set fallback custom fields value.
        let customFieldValues = workItemTypeSpecificWidgets[WIDGET_TYPE_CUSTOM_FIELDS]
          ? typeSpecificCustomFieldValues
          : customFieldsWidgetData?.customFieldValues ?? [];

        if (cachedCustomFieldValues && availableCustomFieldValues) {
          // Create a merged list of custom fields and its values from shared cache & type-specific cache
          customFieldValues = availableCustomFieldValues.map((availableField) => {
            const cachedField = cachedCustomFieldValues.find(
              (cached) => cached.customField.id === availableField.customField.id,
            );
            const typeSpecificField = typeSpecificCustomFieldValues.find(
              (typeField) => typeField.customField.id === availableField.customField.id,
            );

            // Grab appropriate field value
            let fieldValue = {};
            if (cachedField?.selectedOptions || typeSpecificField?.selectedOptions) {
              fieldValue = {
                selectedOptions: cachedField?.selectedOptions || typeSpecificField?.selectedOptions,
              };
            } else if (cachedField?.value || typeSpecificField?.value) {
              fieldValue = { value: cachedField?.value || typeSpecificField?.value };
            }

            // Set field value only if present, return empty field otherwise
            if (Object.keys(fieldValue).length) {
              return {
                ...availableField,
                ...fieldValue,
              };
            }
            return { ...availableField };
          });
        }

        widgets.push({
          type: WIDGET_TYPE_CUSTOM_FIELDS,
          customFieldValues,
          __typename: 'WorkItemWidgetCustomFields',
        });
      }
    }
  });

  return {
    draftTitle,
    draftDescription,
    widgets,
  };
};

export const setNewWorkItemCache = async ({
  fullPath,
  context,
  widgetDefinitions,
  workItemType,
  workItemTypeId,
  workItemTypeIconName,
  relatedItemId,
  workItemTitle = '',
  workItemDescription = '',
  confidential = false,
}) => {
  const workItemAttributesWrapperOrder = [
    WIDGET_TYPE_STATUS,
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
    WIDGET_TYPE_CUSTOM_FIELDS,
    WIDGET_TYPE_HIERARCHY,
    WIDGET_TYPE_TIME_TRACKING,
    WIDGET_TYPE_PARTICIPANTS,
    WIDGET_TYPE_CRM_CONTACTS,
  ];

  if (!widgetDefinitions) {
    return;
  }

  const workItemTitleCase = convertEachWordToTitleCase(workItemType.split('_').join(' '));
  const currentUserId = convertToGraphQLId(TYPENAME_USER, gon?.current_user_id);
  const baseURL = getBaseURL();
  const isValidWorkItemTitle = workItemTitle.trim().length > 0;
  const isValidWorkItemDescription = workItemDescription.trim().length > 0;

  const autosaveKey = getNewWorkItemAutoSaveKey({ fullPath, context, workItemType, relatedItemId });
  const getStorageDraftString = getDraft(autosaveKey);

  const draftData = JSON.parse(getDraft(autosaveKey));
  const widgets = [];

  const sharedCache = getNewWorkItemSharedCache({
    workItemAttributesWrapperOrder,
    widgetDefinitions,
    fullPath,
    context,
    workItemType,
    isValidWorkItemDescription,
    workItemDescription,
    relatedItemId,
  });

  const { draftTitle } = sharedCache;
  widgets.push(...sharedCache.widgets);

  const cacheProvider = await getApolloProvider();

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
          hidden: false,
          imported: false,
          title: isValidWorkItemTitle ? workItemTitle : draftTitle,
          titleHtml: null,
          state: 'OPEN',
          description: null,
          confidential,
          createdAt: null,
          updatedAt: null,
          closedAt: null,
          webUrl: `${baseURL}/groups/gitlab-org/-/work_items/new`,
          reference: '',
          createNoteEmail: null,
          movedToWorkItemUrl: null,
          duplicatedToWorkItemUrl: null,
          promotedToEpicUrl: null,
          showPlanUpgradePromotion: false,
          userDiscussionsCount: 0,
          project: null,
          namespace: {
            id: newWorkItemPath,
            fullPath,
            name: newWorkItemPath,
            fullName: newWorkItemPath,
            webUrl: newWorkItemPath,
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
          userPermissions: newWorkItemOptimisticUserPermissions,
          commentTemplatesPaths: [],
          widgets,
          __typename: 'WorkItem',
        },
        __typename: 'Namespace',
      },
    },
  });
};

export const optimisticUserPermissions = {
  adminParentLink: false,
  adminWorkItemLink: false,
  createNote: false,
  deleteWorkItem: false,
  markNoteAsInternal: false,
  moveWorkItem: false,
  reportSpam: false,
  setWorkItemMetadata: false,
  summarizeComments: false,
  updateWorkItem: false,
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
    const hierarchyWidget = findHierarchyWidget(draft.workItem);

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
