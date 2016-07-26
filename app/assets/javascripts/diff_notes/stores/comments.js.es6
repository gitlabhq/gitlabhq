((w) => {
  w.CommentsStore = {
    state: {},
    loading: {},
    get: function (discussionId, noteId) {
      return this.state[discussionId][noteId];
    },
    create: function (discussionId, noteId, resolved, user) {
      if (!this.state[discussionId]) {
        Vue.set(this.state, discussionId, {});
        Vue.set(this.loading, discussionId, false);
      }

      Vue.set(this.state[discussionId], noteId, { resolved, user});
    },
    update: function (discussionId, noteId, resolved, user) {
      this.state[discussionId][noteId].resolved = resolved;
      this.state[discussionId][noteId].user = user;
    },
    delete: function (discussionId, noteId) {
      Vue.delete(this.state[discussionId], noteId);

      if (Object.keys(this.state[discussionId]).length === 0) {
        Vue.delete(this.state, discussionId);
        Vue.delete(this.loading, discussionId);
      }
    },
    updateCommentsForDiscussion: function (discussionId, resolve, user) {
      const noteIds = CommentsStore.resolvedNotesForDiscussion(discussionId, resolve);

      for (const noteId of noteIds) {
        CommentsStore.update(discussionId, noteId, resolve, user);
      }
    },
    notesForDiscussion: function (discussionId) {
      let ids = [];

      for (const noteId in CommentsStore.state[discussionId]) {
        ids.push(noteId);
      }

      return ids;
    },
    resolvedNotesForDiscussion: function (discussionId, resolve) {
      let ids = [];

      for (const noteId in CommentsStore.state[discussionId]) {
        const resolved = CommentsStore.state[discussionId][noteId].resolved;

        if (resolved !== resolve) {
          ids.push(noteId);
        }
      }

      return ids;
    }
  };
}(window));
