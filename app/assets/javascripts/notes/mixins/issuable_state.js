// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';

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
      return helpPagePath('user/discussions/_index.md', {
        anchor: 'prevent-comments-by-locking-the-discussion',
      });
    },
  },
  methods: {
    isLocked(issue) {
      return Boolean(issue.discussion_locked);
    },
  },
};
