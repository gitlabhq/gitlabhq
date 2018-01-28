export default {
  methods: {
    isConfidential(issue) {
      return !!issue.confidential;
    },

    isLocked(issue) {
      return !!issue.discussion_locked;
    },

    hasWarning(issue) {
      return this.isConfidential(issue) || this.isLocked(issue);
    },
  },
};
