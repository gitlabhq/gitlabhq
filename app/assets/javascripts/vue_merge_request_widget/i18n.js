import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const MR_WIDGET_PREPARING_ASYNCHRONOUSLY = s__(
  'mrWidget|Your merge request is almost ready!',
);

export const MR_WIDGET_MISSING_BRANCH_WHICH = s__(
  'mrWidget|The %{type} branch %{codeStart}%{name}%{codeEnd} does not exist.',
);
export const MR_WIDGET_MISSING_BRANCH_RESTORE = s__(
  'mrWidget|Please restore it or use a different %{type} branch.',
);
export const MR_WIDGET_MISSING_BRANCH_MANUALCLI = s__(
  'mrWidget|If the %{type} branch exists in your local repository, you can merge this merge request manually using the command line.',
);

export const SQUASH_BEFORE_MERGE = {
  tooltipTitle: __('Required in this project.'),
  checkboxLabel: __('Squash commits'),
  helpLabel: __('What is squashing?'),
  popoverOptions: {
    title: __('What is squashing?'),
    content: {
      text: __(
        'Squashing combines multiple commits into a single commit on merge. This keeps your repository history clean and makes it easier to revert changes.',
      ),
      learnMorePath: helpPagePath('user/project/merge_requests/squash_and_merge'),
    },
  },
  learnMore: __('Learn more'),
};

export const I18N_SHA_MISMATCH = {
  warningMessage: s__(
    'mrWidget|%{boldStart}Merge blocked:%{boldEnd} to see new changes and rerun this merge check, refresh this page.',
  ),
  actionButtonLabel: __('Review changes'),
};

export const MERGE_TRAIN_BUTTON_TEXT = {
  failed: __('Start merge train…'),
  passed: __('Start merge train'),
};

export const MR_WIDGET_CLOSED_REOPEN = __('Reopen');
export const MR_WIDGET_CLOSED_REOPENING = __('Reopening…');
export const MR_WIDGET_CLOSED_RELOADING = __('Refreshing…');
export const MR_WIDGET_CLOSED_REOPEN_FAILURE = __(
  'An error occurred. Unable to reopen this merge request.',
);
