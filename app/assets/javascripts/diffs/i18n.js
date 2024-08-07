import { __, s__ } from '~/locale';

export const LOAD_SINGLE_DIFF_FAILED = s__(
  "MergeRequest|Can't fetch the diff needed to update this view. Please reload this page.",
);
export const DISCUSSION_SINGLE_DIFF_FAILED = s__(
  "MergeRequest|Can't fetch the single file diff for the discussion. Please reload this page.",
);

export const DIFF_FILE_HEADER = {
  optionsDropdownTitle: __('Options'),
  fileReviewLabel: __('Viewed'),
  fileReviewTooltip: __('Collapses this file (only for you) until it’s changed again.'),
};

export const DIFF_FILE = {
  tooLarge: s__('MRDiffFile|Changes are too large to be shown.'),
  blobView: s__('MRDiffFile|View file @ %{commitSha}'),
  editInFork: __(
    "You're not allowed to %{tag_start}edit%{tag_end} files in this project directly. Please fork this project, make your changes there, and submit a merge request.",
  ),
  fork: __('Fork'),
  cancel: __('Cancel'),
  autoCollapsed: __('Files with large changes are collapsed by default.'),
  autoCollapsedGenerated: __(
    'Generated files are collapsed by default. To change this behavior, edit the %{tagStart}.gitattributes%{tagEnd} file. %{linkStart}Learn more.%{linkEnd}',
  ),
  expand: __('Expand file'),
};
export const START_THREAD = __('Start another thread');

export const SETTINGS_DROPDOWN = {
  whitespace: __('Show whitespace changes'),
  fileByFile: __('Show one file at a time'),
  preferences: __('Preferences'),
};

export const CONFLICT_TEXT = {
  both_modified: __('Conflict: This file was modified in both the source and target branches.'),
  modified_source_removed_target: __(
    'Conflict: This file was modified in the source branch, but removed in the target branch.',
  ),
  modified_target_removed_source: __(
    'Conflict: This file was removed in the source branch, but modified in the target branch.',
  ),
  renamed_same_file: __(
    'Conflict: This file was renamed differently in the source and target branches.',
  ),
  removed_source_renamed_target: __(
    'Conflict: This file was removed in the source branch, but renamed in the target branch.',
  ),
  removed_target_renamed_source: __(
    'Conflict: This file was renamed in the source branch, but removed in the target branch.',
  ),
  both_added: __(
    'Conflict: This file was added both in the source and target branches, but with different contents.',
  ),
};

export const HIDE_COMMENTS = __('Hide comments');

export const NEW_CODE_QUALITY_FINDINGS = __('New code quality findings');
export const NEW_SAST_FINDINGS = __('New Security findings');

export const BUILDING_YOUR_MR = __(
  'Building your merge request… This page will update when the build is complete.',
);
export const SOMETHING_WENT_WRONG = __('Something went wrong on our end. Please try again!');
export const SAVING_THE_COMMENT_FAILED = s__(
  'MergeRequests|Comment could not be submitted: %{reason}.',
);
export const ERROR_LOADING_FULL_DIFF = s__(
  'MergeRequest|Error loading full diff. Please try again.',
);
export const ERROR_DISMISSING_SUGESTION_POPOVER = s__(
  'MergeRequest|Error dismissing suggestion popover. Please try again.',
);
export const ENCODED_FILE_PATHS_TITLE = __('Some changes are not shown.');
export const ENCODED_FILE_PATHS_MESSAGE = __(
  'Some files cannot be displayed due to their file path encoding.',
);
