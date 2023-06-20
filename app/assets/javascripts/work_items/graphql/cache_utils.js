import { produce } from 'immer';
import { WIDGET_TYPE_NOTES } from '~/work_items/constants';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { findHierarchyWidgetChildren } from '~/work_items/utils';

const isNotesWidget = (widget) => widget.type === WIDGET_TYPE_NOTES;

const getNotesWidgetFromSourceData = (draftData) =>
  draftData?.workspace?.workItems?.nodes[0]?.widgets.find(isNotesWidget);

const updateNotesWidgetDataInDraftData = (draftData, notesWidget) => {
  const noteWidgetIndex = draftData.workspace.workItems.nodes[0].widgets.findIndex(isNotesWidget);
  draftData.workspace.workItems.nodes[0].widgets[noteWidgetIndex] = notesWidget;
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

export const addHierarchyChild = (cache, fullPath, iid, workItem) => {
  const queryArgs = { query: workItemByIidQuery, variables: { fullPath, iid } };
  const sourceData = cache.readQuery(queryArgs);

  if (!sourceData) {
    return;
  }

  cache.writeQuery({
    ...queryArgs,
    data: produce(sourceData, (draftState) => {
      findHierarchyWidgetChildren(draftState.workspace.workItems.nodes[0]).push(workItem);
    }),
  });
};

export const removeHierarchyChild = (cache, fullPath, iid, workItem) => {
  const queryArgs = { query: workItemByIidQuery, variables: { fullPath, iid } };
  const sourceData = cache.readQuery(queryArgs);

  if (!sourceData) {
    return;
  }

  cache.writeQuery({
    ...queryArgs,
    data: produce(sourceData, (draftState) => {
      const children = findHierarchyWidgetChildren(draftState.workspace.workItems.nodes[0]);
      const index = children.findIndex((child) => child.id === workItem.id);
      children.splice(index, 1);
    }),
  });
};
