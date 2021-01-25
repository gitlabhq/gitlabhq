import { __ } from '~/locale';

export const GENERIC_ERROR = __('Something went wrong on our end. Please try again!');

export const DIFF_FILE_HEADER = {
  optionsDropdownTitle: __('Options'),
  fileReviewLabel: __('Viewed'),
  fileReviewTooltip: __('Collapses this file (only for you) until it’s changed again.'),
};

export const DIFF_FILE = {
  blobView: __('You can %{linkStart}view the blob%{linkEnd} instead.'),
  editInFork: __(
    "You're not allowed to %{tag_start}edit%{tag_end} files in this project directly. Please fork this project, make your changes there, and submit a merge request.",
  ),
  fork: __('Fork'),
  cancel: __('Cancel'),
  autoCollapsed: __('Files with large changes are collapsed by default.'),
  expand: __('Expand file'),
};

export const SETTINGS_DROPDOWN = {
  fileByFile: __('Show one file at a time'),
};
