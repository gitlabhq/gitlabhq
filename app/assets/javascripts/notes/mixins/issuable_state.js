import { mapState } from 'pinia';
import { helpPagePath } from '~/helpers/help_page_helper';
import { useNotes } from '~/notes/store/legacy_notes';

export default {
  computed: {
    ...mapState(useNotes, ['getNoteableDataByProp']),
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
