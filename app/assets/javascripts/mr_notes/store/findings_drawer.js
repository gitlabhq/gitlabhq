import { defineStore } from 'pinia';

export const useFindingsDrawer = defineStore('findingsDrawer', {
  state() {
    return {
      activeDrawer: {},
    };
  },
  actions: {
    setDrawer(drawer) {
      this.activeDrawer = drawer;
    },
  },
});
