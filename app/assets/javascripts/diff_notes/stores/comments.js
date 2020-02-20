/* eslint-disable no-restricted-syntax, guard-for-in */
/* global DiscussionModel */

import Vue from 'vue';

window.CommentsStore = {
  state: {},
  get(discussionId, noteId) {
    return this.state[discussionId].getNote(noteId);
  },
  createDiscussion(discussionId, canResolve) {
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
  create(noteObj) {
    const discussion = this.createDiscussion(noteObj.discussionId);

    discussion.createNote(noteObj);
  },
  update(discussionId, noteId, resolved, resolvedBy) {
    const discussion = this.state[discussionId];
    const note = discussion.getNote(noteId);
    note.resolved = resolved;
    note.resolved_by = resolvedBy;
  },
  delete(discussionId, noteId) {
    const discussion = this.state[discussionId];
    discussion.deleteNote(noteId);

    if (discussion.notesCount() === 0) {
      Vue.delete(this.state, discussionId);
    }
  },
  unresolvedDiscussionIds() {
    const ids = [];

    for (const discussionId in this.state) {
      const discussion = this.state[discussionId];

      if (!discussion.isResolved()) {
        ids.push(discussion.id);
      }
    }

    return ids;
  },
};
