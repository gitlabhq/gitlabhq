import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters(['getNoteableDataByProp']),
    isProjectArchived() {
      return this.getNoteableDataByProp('is_project_archived');
    },
    archivedProjectDocsPath() {
      return this.getNoteableDataByProp('archived_project_docs_path');
    },
    lockedIssueDocsPath() {
      return this.getNoteableDataByProp('locked_discussion_docs_path');
    },
    confidentialIssueDocsPath() {
      return this.getNoteableDataByProp('confidential_issues_docs_path');
    },
  },
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
