class NoteModel {
  constructor (discussionId, noteId, resolved, resolved_by) {
    this.discussionId = discussionId;
    this.id = noteId;
    this.resolved = resolved;
    this.resolved_by = resolved_by;
  }
}
