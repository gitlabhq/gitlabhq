export default {
  computed: {
    shouldRenderDraftRow: () => () => false,
    shouldRenderParallelDraftRow: () => () => false,
    draftForLine: () => () => ({}),
    imageDiscussions() {
      return this.diffFile.discussions;
    },
    hasParallelDraftLeft: () => () => false,
    hasParallelDraftRight: () => () => false,
  },
};
