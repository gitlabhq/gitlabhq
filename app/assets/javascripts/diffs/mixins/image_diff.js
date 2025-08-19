import { mapActions } from 'pinia';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';

export default {
  methods: {
    ...mapActions(useLegacyDiffs, ['toggleFileDiscussion']),
    clickedToggle(discussion) {
      this.toggleFileDiscussion(discussion);
    },
    toggleText(discussion, index) {
      return index + 1;
    },
  },
};
