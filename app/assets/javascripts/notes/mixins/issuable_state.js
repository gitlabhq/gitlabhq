/* globals Autosave */
import '../../autosave';

export default {
  computed: {
    isIssueConfidential() {
      return !!this.getIssueData.confidential;
    },

    isIssueLocked() {
      return !!this.getIssueData.discussion_locked;
    },

    hasIssueWarning() {
      return this.isIssueConfidential || this.isIssueLocked;
    },
  },
};
