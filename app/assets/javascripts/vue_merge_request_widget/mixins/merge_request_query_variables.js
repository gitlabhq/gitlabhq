export default {
  computed: {
    mergeRequestQueryVariables() {
      return {
        projectPath: this.mr.targetProjectFullPath,
        iid: `${this.mr.iid}`,
      };
    },
  },
};
