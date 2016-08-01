class DiscussionModel {
  constructor (discussionId) {
    this.id = discussionId;
    this.notes = {};
    this.loading = false;
  }

  createNote (noteId, resolved, resolved_by) {
    Vue.set(this.notes, noteId, new NoteModel(this.id, noteId, resolved, resolved_by));
  }

  deleteNote (noteId) {
    Vue.delete(this.notes, noteId);
  }

  getNote (noteId) {
    return this.notes[noteId];
  }

  notesCount() {
    return Object.keys(this.notes).length;
  }

  isResolved () {
    for (const noteId in this.notes) {
      const note = this.notes[noteId];

      if (!note.resolved) {
        return false;
      }
    }
    return true;
  }

  resolveAllNotes (resolved_by) {
    for (const noteId in this.notes) {
      const note = this.notes[noteId];

      if (!note.resolved) {
        note.resolved = true;
        note.resolved_by = resolved_by;
      }
    }
  }

  unResolveAllNotes () {
    for (const noteId in this.notes) {
      const note = this.notes[noteId];

      if (note.resolved) {
        note.resolved = false;
        note.resolved_by = null;
      }
    }
  }
}
