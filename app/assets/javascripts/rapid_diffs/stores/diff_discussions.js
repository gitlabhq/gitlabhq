import { defineStore } from 'pinia';
import { merge } from 'lodash';

export const useDiffDiscussions = defineStore('diffDiscussions', {
  state() {
    return {
      discussions: [],
    };
  },
  actions: {
    // Pinia objects are fine to mutate if they have the properties defined initially
    /* eslint-disable no-param-reassign */
    setInitialDiscussions(discussions) {
      this.discussions = discussions.map((discussion) => {
        // add dynamic properties so that they're reactively tracked
        return Object.assign(discussion, { repliesExpanded: true });
      });
    },
    toggleDiscussionReplies(discussion) {
      discussion.repliesExpanded = !discussion.repliesExpanded;
    },
    expandDiscussionReplies(discussion) {
      discussion.repliesExpanded = true;
    },
    addNote(note) {
      const { notes } = this.getDiscussionById(note.discussion_id);
      if (notes.some((existingNote) => existingNote.id === note.id)) return;
      notes.push(note);
    },
    updateNote(note) {
      merge(this.allNotesById[note.id], note);
    },
    deleteNote(note) {
      const { notes } = this.getDiscussionById(note.discussion_id);
      notes.splice(notes.indexOf(note), 1);
    },
    /* eslint-enable no-param-reassign */
  },
  getters: {
    getDiscussionById() {
      return (id) => this.discussions.find((discussion) => discussion.id === id);
    },
    allNotesById() {
      return this.discussions.reduce((acc, discussion) => {
        discussion.notes.forEach((note) => Object.assign(acc, { [note.id]: note }));
        return acc;
      }, {});
    },
  },
});
