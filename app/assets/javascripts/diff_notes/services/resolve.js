/* eslint-disable class-methods-use-this, one-var, camelcase, no-new, comma-dangle, no-param-reassign, max-len */
/* global Flash */
/* global CommentsStore */

import Vue from 'vue';
import VueResource from 'vue-resource';

require('../../vue_shared/vue_resource_interceptor');

Vue.use(VueResource);

window.gl = window.gl || {};

class ResolveServiceClass {
  constructor(root) {
    this.noteResource = Vue.resource(`${root}/notes{/noteId}/resolve`);
    this.discussionResource = Vue.resource(`${root}/merge_requests{/mergeRequestId}/discussions{/discussionId}/resolve`);
  }

  resolve(noteId) {
    return this.noteResource.save({ noteId }, {});
  }

  unresolve(noteId) {
    return this.noteResource.delete({ noteId }, {});
  }

  toggleResolveForDiscussion(mergeRequestId, discussionId) {
    const discussion = CommentsStore.state[discussionId];
    const isResolved = discussion.isResolved();
    let promise;

    if (isResolved) {
      promise = this.unResolveAll(mergeRequestId, discussionId);
    } else {
      promise = this.resolveAll(mergeRequestId, discussionId);
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

        gl.mrWidget.checkStatus();
        discussion.updateHeadline(data);
      } else {
        throw new Error('An error occurred when trying to resolve discussion.');
      }
    }).catch(() => {
      new Flash('An error occurred when trying to resolve a discussion. Please try again.');
    });
  }

  resolveAll(mergeRequestId, discussionId) {
    const discussion = CommentsStore.state[discussionId];

    discussion.loading = true;

    return this.discussionResource.save({
      mergeRequestId,
      discussionId
    }, {});
  }

  unResolveAll(mergeRequestId, discussionId) {
    const discussion = CommentsStore.state[discussionId];

    discussion.loading = true;

    return this.discussionResource.delete({
      mergeRequestId,
      discussionId
    }, {});
  }
}

gl.DiffNotesResolveServiceClass = ResolveServiceClass;
