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
