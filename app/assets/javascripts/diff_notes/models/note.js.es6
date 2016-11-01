/* eslint-disable */
class NoteModel {
  constructor (discussionId, noteId, canResolve, resolved, resolved_by) {
    this.discussionId = discussionId;
    this.id = noteId;
    this.canResolve = canResolve;
    this.resolved = resolved;
    this.resolved_by = resolved_by;
  }
}
