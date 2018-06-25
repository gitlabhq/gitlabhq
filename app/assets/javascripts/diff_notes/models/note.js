class NoteModel {
  constructor(discussionId, noteObj) {
    this.discussionId = discussionId;
    this.id = noteObj.noteId;
    this.canResolve = noteObj.canResolve;
    this.resolved = noteObj.resolved;
    this.resolved_by = noteObj.resolvedBy;
    this.authorName = noteObj.authorName;
    this.authorAvatar = noteObj.authorAvatar;
    this.noteTruncated = noteObj.noteTruncated;
  }
}

window.NoteModel = NoteModel;
