import { produce } from 'immer';
import { findHierarchyWidgetChildren, isNotesWidget } from '../utils';
import groupWorkItemByIidQuery from './group_work_item_by_iid.query.graphql';
import workItemByIidQuery from './work_item_by_iid.query.graphql';

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

export const addHierarchyChild = ({ cache, fullPath, iid, isGroup, workItem }) => {
  const queryArgs = {
    query: isGroup ? groupWorkItemByIidQuery : workItemByIidQuery,
    variables: { fullPath, iid },
  };
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

export const removeHierarchyChild = ({ cache, fullPath, iid, isGroup, workItem }) => {
  const queryArgs = {
    query: isGroup ? groupWorkItemByIidQuery : workItemByIidQuery,
    variables: { fullPath, iid },
  };
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
