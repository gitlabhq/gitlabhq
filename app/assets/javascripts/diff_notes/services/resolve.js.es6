((w) => {
  class ResolveServiceClass {
    constructor() {
      this.noteResource = Vue.resource('notes{/noteId}/resolve');
      this.discussionResource = Vue.resource('merge_requests{/mergeRequestId}/discussions{/discussionId}/resolve');
    }

    setCSRF() {
      Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken();
    }

    resolve(namespace, noteId) {
      this.setCSRF();
      Vue.http.options.root = `/${namespace}`;

      return this.noteResource.save({ noteId }, {});
    }

    unresolve(namespace, noteId) {
      this.setCSRF();
      Vue.http.options.root = `/${namespace}`;

      return this.noteResource.delete({ noteId }, {});
    }

    toggleResolveForDiscussion(namespace, mergeRequestId, discussionId) {
      const noteIds = CommentsStore.notesForDiscussion(discussionId);
      let isResolved = true;

      for (const noteId of noteIds) {
        const resolved = CommentsStore.state[discussionId][noteId];

        if (!resolved) {
          isResolved = false;
        }
      }

      if (isResolved) {
        return this.unResolveAll(namespace, mergeRequestId, discussionId);
      } else {
        return this.resolveAll(namespace, mergeRequestId, discussionId);
      }
    }

    resolveAll(namespace, mergeRequestId, discussionId) {
      this.setCSRF();
      Vue.http.options.root = `/${namespace}`;

      CommentsStore.loading[discussionId] = true;

      return this.discussionResource.save({
        mergeRequestId,
        discussionId
      }, {}).then((response) => {
        CommentsStore.loading[discussionId] = false;

        CommentsStore.updateCommentsForDiscussion(discussionId, true);
      });
    }

    unResolveAll(namespace, mergeRequestId, discussionId) {
      this.setCSRF();
      Vue.http.options.root = `/${namespace}`;

      CommentsStore.loading[discussionId] = true;

      return this.discussionResource.delete({
        mergeRequestId,
        discussionId
      }, {}).then((response) => {
        CommentsStore.loading[discussionId] = false;

        CommentsStore.updateCommentsForDiscussion(discussionId, false);
      });
    }
  }

  w.ResolveService = new ResolveServiceClass();
}(window));
