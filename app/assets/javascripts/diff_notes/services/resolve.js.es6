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
      const isResolved = CommentsStore.state[discussionId].isResolved();

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
        const data = response.data;
        const user = data ? data.resolved_by : null;
        const discussion = CommentsStore.state[discussionId];
        discussion.resolveAllNotes(user);

        CommentsStore.loading[discussionId] = false;


        this.updateUpdatedHtml(discussionId, data);
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
        const data = response.data;
        const discussion = CommentsStore.state[discussionId];
        discussion.unResolveAllNotes();

        CommentsStore.loading[discussionId] = false;

        this.updateUpdatedHtml(discussionId, data);
      });
    }

    updateUpdatedHtml(discussionId, data) {
      const $discussionHeadline = $(`.discussion[data-discussion-id="${discussionId}"] .js-discussion-headline`);

      if (data.discussion_headline_html) {
        if ($discussionHeadline.length) {
          $discussionHeadline.replaceWith(data.discussion_headline_html);
        } else {
          $(`.discussion[data-discussion-id="${discussionId}"] .discussion-header`).append(data.discussion_headline_html);
        }
      } else {
         $discussionHeadline.remove();
      }
    }
  }

  w.ResolveService = new ResolveServiceClass();
})(window);
