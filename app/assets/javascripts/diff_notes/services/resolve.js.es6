/* eslint-disable */
((w) => {
  class ResolveServiceClass {
    constructor() {
      this.noteResource = Vue.resource('notes{/noteId}/resolve');
      this.discussionResource = Vue.resource('merge_requests{/mergeRequestId}/discussions{/discussionId}/resolve');
    }

    setCSRF() {
      Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken();
    }

    prepareRequest(root) {
      this.setCSRF();
      Vue.http.options.root = root;
    }

    resolve(projectPath, noteId) {
      this.prepareRequest(projectPath);

      return this.noteResource.save({ noteId }, {});
    }

    unresolve(projectPath, noteId) {
      this.prepareRequest(projectPath);

      return this.noteResource.delete({ noteId }, {});
    }

    toggleResolveForDiscussion(projectPath, mergeRequestId, discussionId) {
      const discussion = CommentsStore.state[discussionId],
            isResolved = discussion.isResolved();
      let promise;

      if (isResolved) {
        promise = this.unResolveAll(projectPath, mergeRequestId, discussionId);
      } else {
        promise = this.resolveAll(projectPath, mergeRequestId, discussionId);
      }

      promise.then((response) => {
        discussion.loading = false;

        if (response.status === 200) {
          const data = response.json();
          const resolved_by = data ? data.resolved_by : null;

          if (isResolved) {
            discussion.unResolveAllNotes();
          } else {
            discussion.resolveAllNotes(resolved_by);
          }

          discussion.updateHeadline(data);
        } else {
          new Flash('An error occurred when trying to resolve a discussion. Please try again.', 'alert');
        }
      })
    }

    resolveAll(projectPath, mergeRequestId, discussionId) {
      const discussion = CommentsStore.state[discussionId];

      this.prepareRequest(projectPath);

      discussion.loading = true;

      return this.discussionResource.save({
        mergeRequestId,
        discussionId
      }, {});
    }

    unResolveAll(projectPath, mergeRequestId, discussionId) {
      const discussion = CommentsStore.state[discussionId];

      this.prepareRequest(projectPath);

      discussion.loading = true;

      return this.discussionResource.delete({
        mergeRequestId,
        discussionId
      }, {});
    }
  }

  w.ResolveService = new ResolveServiceClass();
})(window);
