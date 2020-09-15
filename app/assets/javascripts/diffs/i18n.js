import { __ } from '~/locale';

export const GENERIC_ERROR = __('Something went wrong on our end. Please try again!');

export const DIFF_FILE = {
  blobView: __('You can %{linkStart}view the blob%{linkEnd} instead.'),
  editInFork: __(
    "You're not allowed to %{tag_start}edit%{tag_end} files in this project directly. Please fork this project, make your changes there, and submit a merge request.",
  ),
  fork: __('Fork'),
  cancel: __('Cancel'),
  collapsed: __('This file is collapsed.'),
  expand: __('Expand file'),
};
