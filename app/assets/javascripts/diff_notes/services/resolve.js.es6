/* eslint-disable class-methods-use-this, one-var, camelcase, no-new, comma-dangle, no-param-reassign, max-len */
/* global Vue */
/* global Flash */
/* global CommentsStore */

window.Vue.use(require('vue-resource'));

(() => {
  window.ResolveServiceClass = class ResolveServiceClass {
    constructor(rootPath) {
      this.noteResource = Vue.resource(`${rootPath}/notes{/noteId}/resolve`);
      this.discussionResource = Vue.resource(`${rootPath}/merge_requests{/mergeRequestId}/discussions{/discussionId}/resolve`);
    }

    setCSRF() {
      Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken();
    }

    prepareRequest() {
      this.setCSRF();
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
      const discussion = CommentsStore.state[discussionId];
      const isResolved = discussion.isResolved();
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
      });
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
})();
