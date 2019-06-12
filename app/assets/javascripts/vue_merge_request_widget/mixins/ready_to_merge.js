import { __ } from '~/locale';

export default {
  computed: {
    isMergeButtonDisabled() {
      const { commitMessage } = this;
      return Boolean(
        !commitMessage.length ||
          !this.shouldShowMergeControls ||
          this.isMakingRequest ||
          this.mr.preventMerge,
      );
    },
    autoMergeText() {
      // MWPS is currently the only auto merge strategy available in CE
      return __('Merge when pipeline succeeds');
    },
  },
};
