/* globals Autosave */
import '../../autosave';

export default {
  methods: {
    isIssueConfidential(issue) {
      return !!issue.confidential;
    },

    isIssueLocked(issue) {
      return !!issue.discussion_locked;
    },

    hasIssueWarning(issue) {
      return this.isIssueConfidential(issue) || this.isIssueLocked(issue);
    },
  },
};
