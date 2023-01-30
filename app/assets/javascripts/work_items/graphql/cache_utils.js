import { produce } from 'immer';
import { WIDGET_TYPE_NOTES } from '~/work_items/constants';
import { ASC } from '~/notes/constants';
import { getWorkItemNotesQuery } from '~/work_items/utils';

/**
 * Updates the cache manually when adding a main comment
 *
 * @param store
 * @param createNoteData
 * @param fetchByIid
 * @param queryVariables
 * @param sortOrder
 */
export const updateCommentState = (
  store,
  { data: { createNote } },
  fetchByIid,
  queryVariables,
  sortOrder,
) => {
  const notesQuery = getWorkItemNotesQuery(fetchByIid);
  const variables = {
    ...queryVariables,
    pageSize: 100,
  };
  const sourceData = store.readQuery({
    query: notesQuery,
    variables,
  });

  const finalData = produce(sourceData, (draftData) => {
    const notesWidget = fetchByIid
      ? draftData.workspace.workItems.nodes[0].widgets.find(
          (widget) => widget.type === WIDGET_TYPE_NOTES,
        )
      : draftData.workItem.widgets.find((widget) => widget.type === WIDGET_TYPE_NOTES);

    const arrayPushMethod = sortOrder === ASC ? 'push' : 'unshift';

    // manual update of cache with a completely new discussion
    if (createNote.note.discussion.notes.nodes.length === 1) {
      notesWidget.discussions.nodes[arrayPushMethod]({
        id: createNote.note.discussion.id,
        notes: {
          nodes: createNote.note.discussion.notes.nodes,
          __typename: 'NoteConnection',
        },
        // eslint-disable-next-line @gitlab/require-i18n-strings
        __typename: 'Discussion',
      });
    }

    if (fetchByIid) {
      draftData.workspace.workItems.nodes[0].widgets[6] = notesWidget;
    } else {
      draftData.workItem.widgets[6] = notesWidget;
    }
  });

  store.writeQuery({
    query: notesQuery,
    variables,
    data: finalData,
  });
};
