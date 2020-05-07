import { __ } from '~/locale';

export const MERGE_DISABLED_TEXT = __('You can only merge once the items above are resolved.');
export const PIPELINE_MUST_SUCCEED_CONFLICT_TEXT = __(
  'Pipelines must succeed for merge requests to be eligible to merge. Please enable pipelines for this project to continue. For more information, see the %{linkStart}documentation.%{linkEnd}',
);

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
    mergeDisabledText() {
      return MERGE_DISABLED_TEXT;
    },
    pipelineMustSucceedConflictText() {
      return PIPELINE_MUST_SUCCEED_CONFLICT_TEXT;
    },
    autoMergeText() {
      // MWPS is currently the only auto merge strategy available in CE
      return __('Merge when pipeline succeeds');
    },
    shouldShowMergeImmediatelyDropdown() {
      return this.mr.isPipelineActive && !this.mr.onlyAllowMergeIfPipelineSucceeds;
    },
    isMergeImmediatelyDangerous() {
      return false;
    },
  },
};
