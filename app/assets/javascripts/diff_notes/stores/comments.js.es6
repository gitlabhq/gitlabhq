((w) => {
  w.CommentsStore = {
    state: {},
    get: function (discussionId, noteId) {
      return this.state[discussionId].getNote(noteId);
    },
    create: function (discussionId, noteId, canResolve, resolved, resolved_by) {
      let discussion = this.state[discussionId];
      if (!this.state[discussionId]) {
        discussion = new DiscussionModel(discussionId);
        Vue.set(this.state, discussionId, discussion);
      }

      discussion.createNote(noteId, canResolve, resolved, resolved_by);
    },
    update: function (discussionId, noteId, resolved, resolved_by) {
      const discussion = this.state[discussionId];
      const note = discussion.getNote(noteId);
      note.resolved = resolved;
      note.resolved_by = resolved_by;
    },
    delete: function (discussionId, noteId) {
      const discussion = this.state[discussionId];
      discussion.deleteNote(noteId);

      if (discussion.notesCount() === 0) {
        Vue.delete(this.state, discussionId);
      }
    },
    unresolvedDiscussionIds: function () {
      let ids = [];

      for (const discussionId in this.state) {
        const discussion = this.state[discussionId];

        if (!discussion.isResolved()) {
          ids.push(discussion.id);
        }
      }

      return ids;
    }
  };
})(window);
