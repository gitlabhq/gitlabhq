import { defineStore } from 'pinia';

export const useApp = defineStore('rapidDiffsApp', {
  state() {
    return {
      appVisible: true,
    };
  },
});
