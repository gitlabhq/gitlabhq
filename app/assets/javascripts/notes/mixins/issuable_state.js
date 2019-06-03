export default {
  methods: {
    isConfidential(issue) {
      return Boolean(issue.confidential);
    },

    isLocked(issue) {
      return Boolean(issue.discussion_locked);
    },

    hasWarning(issue) {
      return this.isConfidential(issue) || this.isLocked(issue);
    },
  },
};
