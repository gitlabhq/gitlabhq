import { helpPagePath } from '~/helpers/help_page_helper';
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
    autoMergeTextLegacy() {
      // MWPS is currently the only auto merge strategy available in CE
      return __('Merge when pipeline succeeds');
    },
    autoMergeText() {
      return __('Set to auto-merge');
    },
    autoMergeHelperText() {
      return __('Merge when pipeline succeeds');
    },
    autoMergePopoverSettings() {
      return {
        helpLink: helpPagePath('/user/project/merge_requests/merge_when_pipeline_succeeds.html'),
        bodyText: __(
          'When the pipeline for this merge request succeeds, it will %{linkStart}automatically merge%{linkEnd}.',
        ),
        title: __('Merge when pipeline succeeds'),
      };
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
