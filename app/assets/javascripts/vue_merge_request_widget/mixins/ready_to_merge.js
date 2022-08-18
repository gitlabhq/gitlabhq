import { __ } from '~/locale';

export const MERGE_DISABLED_TEXT = __('You can only merge once the items above are resolved.');
export const MERGE_DISABLED_SKIPPED_PIPELINE_TEXT = __(
  "Merge blocked: pipeline must succeed. It's waiting for a manual job to continue.",
);
export const PIPELINE_MUST_SUCCEED_CONFLICT_TEXT = __(
  'A CI/CD pipeline must run and be successful before merge.',
);
export const PIPELINE_SKIPPED_STATUS = 'SKIPPED';

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
      if (this.pipeline?.status === PIPELINE_SKIPPED_STATUS) {
        return MERGE_DISABLED_SKIPPED_PIPELINE_TEXT;
      }

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
      return this.isPipelineActive && !this.stateData.onlyAllowMergeIfPipelineSucceeds;
    },
    isMergeImmediatelyDangerous() {
      return false;
    },
    shouldRenderMergeTrainHelperIcon() {
      return false;
    },
    pipelineId() {
      return this.pipeline.id;
    },
    showFailedPipelineModalMergeTrain() {
      return false;
    },
  },
  methods: {
    onStartMergeTrainConfirmation() {
      return false;
    },
  },
};
