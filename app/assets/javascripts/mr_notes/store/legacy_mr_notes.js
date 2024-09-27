import { defineStore } from 'pinia';

export const useMrNotes = defineStore('legacyMrNotes', {
  state() {
    return {
      page: {
        mrMetadata: {},
      },
    };
  },
});
