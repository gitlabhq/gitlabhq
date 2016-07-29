class NoteModel {
  constructor (discussionId, noteId, resolved, user) {
    this.discussionId = discussionId;
    this.id = noteId;
    this.resolved = resolved;
    this.user = user;
  }
}
