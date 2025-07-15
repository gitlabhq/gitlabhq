import { mapState } from 'pinia';
import { helpPagePath } from '~/helpers/help_page_helper';
import { useNotes } from '~/notes/store/legacy_notes';

export default {
  computed: {
    ...mapState(useNotes, ['getNoteableDataByProp']),
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
