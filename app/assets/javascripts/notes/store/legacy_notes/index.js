import { defineStore } from 'pinia';

export const useNotes = defineStore('legacyNotes', {
  state() {
    return {
      notes: null,
    };
  },
  actions: {
    saveNote() {},
    updateDiscussion() {},
    updateResolvableDiscussionsCounts() {},
  },
  getters: {
    notesById() {},
    getDiscussion() {},
  },
});
