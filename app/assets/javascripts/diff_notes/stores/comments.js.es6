((w) => {
  w.CommentsStore = {
    state: {},
    loading: {},
    get: function (discussionId, noteId) {
      return this.state[discussionId][noteId];
    },
    create: function (discussionId, noteId, resolved) {
      if (!this.state[discussionId]) {
        Vue.set(this.state, discussionId, {});
        Vue.set(this.loading, discussionId, false);
      }

      Vue.set(this.state[discussionId], noteId, resolved);
    },
    update: function (discussionId, noteId, resolved) {
      this.state[discussionId][noteId] = resolved;
    },
    delete: function (discussionId, noteId) {
      Vue.delete(this.state[discussionId], noteId);

      if (Object.keys(this.state[discussionId]).length === 0) {
        Vue.delete(this.state, discussionId);
        Vue.delete(this.loading, discussionId);
      }
    },
    updateCommentsForDiscussion: function (discussionId, resolve) {
      const noteIds = CommentsStore.resolvedNotesForDiscussion(discussionId, resolve);

      for (const noteId of noteIds) {
        CommentsStore.update(discussionId, noteId, resolve);
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
        const resolved = CommentsStore.state[discussionId][noteId];

        if (resolved !== resolve) {
          ids.push(noteId);
        }
      }

      return ids;
    }
  };
}(window));
