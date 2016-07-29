class DiscussionModel {
  constructor (discussionId) {
    this.id = discussionId;
    this.notes = {};
    this.loading = false;
  }

  createNote (noteId, resolved, user) {
    Vue.set(this.notes, noteId, new NoteModel(this.id, noteId, resolved, user));
  }

  deleteNote (noteId) {
    Vue.delete(this.notes, noteId);
  }

  getNote (noteId) {
    return this.notes[noteId];
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

  resolveAllNotes (user) {
    for (const noteId in this.notes) {
      const note = this.notes[noteId];

      if (!note.resolved) {
        note.resolved = true;
        note.user = user;
      }
    }
  }

  unResolveAllNotes (user) {
    for (const noteId in this.notes) {
      const note = this.notes[noteId];

      if (note.resolved) {
        note.resolved = false;
        note.user = null;
      }
    }
  }
}
