/* eslint-disable space-before-function-paren, camelcase, guard-for-in, no-restricted-syntax, no-unused-vars, max-len */
/* global NoteModel */

import Vue from 'vue';

class DiscussionModel {
  constructor (discussionId) {
    this.id = discussionId;
    this.notes = {};
    this.loading = false;
    this.canResolve = false;
    this.resolved = false;
  }

  createNote (noteObj) {
    Vue.set(this.notes, noteObj.noteId, new NoteModel(this.id, noteObj));

    this.resolved = noteObj.resolved;
  }

  deleteNote (noteId) {
    Vue.delete(this.notes, noteId);
  }

  getNote (noteId) {
    return this.notes[noteId];
  }

  notesCount() {
    return Object.keys(this.notes).length;
  }

  isResolved () {
    return _.every(this.notes, note => note.resolved);
  }

  resolveAllNotes (resolved_by) {
    _.each(this.notes, (note) => {
      if (!note.resolved) {
        note.resolved = true; // eslint-disable-line no-param-reassign
        note.resolved_by = resolved_by; // eslint-disable-line no-param-reassign
      }
    });

    this.resolved = true;
  }

  unResolveAllNotes () {
    _.each(this.notes, (note) => {
      if (note.resolved) {
        note.resolved = false; // eslint-disable-line no-param-reassign
        note.resolved_by = null; // eslint-disable-line no-param-reassign
      }
    });

    this.resolved = false;
  }

  updateHeadline (data) {
    const discussionSelector = `.discussion[data-discussion-id="${this.id}"]`;
    const $discussionHeadline = $(`${discussionSelector} .js-discussion-headline`);

    if (data.discussion_headline_html) {
      if ($discussionHeadline.length) {
        $discussionHeadline.replaceWith(data.discussion_headline_html);
      } else {
        $(`${discussionSelector} .discussion-header`).append(data.discussion_headline_html);
      }

      gl.utils.localTimeAgo($('.js-timeago', `${discussionSelector}`));
    } else {
      $discussionHeadline.remove();
    }
  }

  isResolvable () {
    if (!this.canResolve) {
      return false;
    }

    for (const noteId in this.notes) {
      const note = this.notes[noteId];

      if (note.canResolve) {
        return true;
      }
    }

    return false;
  }
}

window.DiscussionModel = DiscussionModel;
