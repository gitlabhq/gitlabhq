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
      const isResolved = CommentsStore.state[discussionId].isResolved();

      if (isResolved) {
        return this.unResolveAll(namespace, mergeRequestId, discussionId);
      } else {
        return this.resolveAll(namespace, mergeRequestId, discussionId);
      }
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
      }, {}).then((response) => {
        if (response.status === 200) {
          const data = response.json();
          const resolved_by = data ? data.resolved_by : null;
          discussion.resolveAllNotes(resolved_by);
          discussion.loading = false;

          this.updateDiscussionHeadline(discussionId, data);
        } else {
          new Flash('An error occurred when trying to resolve a discussion. Please try again.', 'alert');
        }
      });
    }

    unResolveAll(namespace, mergeRequestId, discussionId) {
      const discussion = CommentsStore.state[discussionId];

      this.setCSRF();
      Vue.http.options.root = `/${namespace}`;

      discussion.loading = true;

      return this.discussionResource.delete({
        mergeRequestId,
        discussionId
      }, {}).then((response) => {
        if (response.status === 200) {
          const data = response.json();
          discussion.unResolveAllNotes();
          discussion.loading = false;

          this.updateDiscussionHeadline(discussionId, data);
        } else {
          new Flash('An error occurred when trying to unresolve a discussion. Please try again.', 'alert');
        }
      });
    }

    updateDiscussionHeadline(discussionId, data) {
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
