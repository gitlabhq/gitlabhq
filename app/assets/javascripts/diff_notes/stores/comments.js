/* eslint-disable object-shorthand, func-names, camelcase, no-restricted-syntax, guard-for-in, comma-dangle, max-len */
/* global DiscussionModel */

import Vue from 'vue';

window.CommentsStore = {
  state: {},
  get: function (discussionId, noteId) {
    return this.state[discussionId].getNote(noteId);
  },
  createDiscussion: function (discussionId, canResolve) {
    let discussion = this.state[discussionId];
    if (!this.state[discussionId]) {
      discussion = new DiscussionModel(discussionId);
      Vue.set(this.state, discussionId, discussion);
    }

    if (canResolve !== undefined) {
      discussion.canResolve = canResolve;
    }

    return discussion;
  },
  create: function (noteObj) {
    const discussion = this.createDiscussion(noteObj.discussionId);

    discussion.createNote(noteObj);
  },
  update: function (discussionId, noteId, resolved, resolved_by) {
    const discussion = this.state[discussionId];
    const note = discussion.getNote(noteId);
    note.resolved = resolved;
    note.resolved_by = resolved_by;
  },
  delete: function (discussionId, noteId) {
    const discussion = this.state[discussionId];
    discussion.deleteNote(noteId);

    if (discussion.notesCount() === 0) {
      Vue.delete(this.state, discussionId);
    }
  },
  unresolvedDiscussionIds: function () {
    const ids = [];

    for (const discussionId in this.state) {
      const discussion = this.state[discussionId];

      if (!discussion.isResolved()) {
        ids.push(discussion.id);
      }
    }

    return ids;
  }
};
