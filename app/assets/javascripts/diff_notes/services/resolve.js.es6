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
      if (Vue.http.options.root !== `/${namespace}`) {
        Vue.http.options.root = `/${namespace}`;
      }

      return this.noteResource.save({ noteId }, {});
    }

    unresolve(namespace, noteId) {
      this.setCSRF();
      if (Vue.http.options.root !== `/${namespace}`) {
        Vue.http.options.root = `/${namespace}`;
      }

      return this.noteResource.delete({ noteId }, {});
    }

    toggleResolveForDiscussion(namespace, mergeRequestId, discussionId) {
      const discussion = CommentsStore.state[discussionId],
            isResolved = discussion.isResolved();
      let promise;

      if (isResolved) {
        promise = this.unResolveAll(namespace, mergeRequestId, discussionId);
      } else {
        promise = this.resolveAll(namespace, mergeRequestId, discussionId);
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

    resolveAll(namespace, mergeRequestId, discussionId) {
      const discussion = CommentsStore.state[discussionId];

      this.setCSRF();

      if (Vue.http.options.root !== `/${namespace}`) {
        Vue.http.options.root = `/${namespace}`;
      }

      discussion.loading = true;

      return this.discussionResource.save({
        mergeRequestId,
        discussionId
      }, {});
    }

    unResolveAll(namespace, mergeRequestId, discussionId) {
      const discussion = CommentsStore.state[discussionId];

      this.setCSRF();
      Vue.http.options.root = `/${namespace}`;

      discussion.loading = true;

      return this.discussionResource.delete({
        mergeRequestId,
        discussionId
      }, {});
    }
  }

  w.ResolveService = new ResolveServiceClass();
})(window);
