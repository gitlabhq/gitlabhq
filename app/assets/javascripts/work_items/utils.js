import workItemQuery from './graphql/work_item.query.graphql';
import workItemByIidQuery from './graphql/work_item_by_iid.query.graphql';
import workItemNotesIdQuery from './graphql/work_item_notes.query.graphql';
import workItemNotesByIidQuery from './graphql/work_item_notes_by_iid.query.graphql';

export function getWorkItemQuery(isFetchedByIid) {
  return isFetchedByIid ? workItemByIidQuery : workItemQuery;
}

export function getWorkItemNotesQuery(isFetchedByIid) {
  return isFetchedByIid ? workItemNotesByIidQuery : workItemNotesIdQuery;
}
