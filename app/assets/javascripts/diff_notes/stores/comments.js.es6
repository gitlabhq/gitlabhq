((w) => {
  w.CommentsStore = {
    state: {},
    get: function (discussionId, noteId) {
      return this.state[discussionId].getNote(noteId);
    },
    create: function (discussionId, noteId, resolved, user) {
      let discussion = this.state[discussionId];
      if (!this.state[discussionId]) {
        discussion = new DiscussionModel(discussionId);
        Vue.set(this.state, discussionId, discussion);
      }

      discussion.createNote(noteId, resolved, user);
    },
    update: function (discussionId, noteId, resolved, user) {
      const discussion = this.state[discussionId];
      const note = discussion.getNote(noteId);
      note.resolved = resolved;
      note.user = user;
    },
    delete: function (discussionId, noteId) {
      const discussion = this.state[discussionId];
      discussion.deleteNote(noteId);

      if (Object.keys(discussion.notes).length === 0) {
        Vue.delete(this.state, discussionId);
      }
    }
  };
})(window);
