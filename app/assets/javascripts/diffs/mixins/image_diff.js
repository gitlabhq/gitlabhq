import { mapActions } from 'pinia';
import { useNotes } from '~/notes/store/legacy_notes';

export default {
  methods: {
    ...mapActions(useNotes, ['toggleDiscussion']),
    clickedToggle(discussion) {
      this.toggleDiscussion({ discussionId: discussion.id });
    },
    toggleText(discussion, index) {
      return index + 1;
    },
  },
};
