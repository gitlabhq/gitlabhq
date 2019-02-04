export default {
  methods: {
    handleSelected(file, sectionId, selection) {
      gl.mergeConflicts.mergeConflictsStore.handleSelected(file, sectionId, selection);
    },
  },
};
