import { __, s__ } from '~/locale';

export const COMMENT_FORM = {
  GENERIC_UNSUBMITTABLE_NETWORK: __(
    'Your comment could not be submitted! Please check your network connection and try again.',
  ),
  note: __('Note'),
  comment: __('Comment'),
  issue: __('issue'),
  startThread: __('Start thread'),
  mergeRequest: __('merge request'),
  bodyPlaceholder: __('Write a comment or drag your files here…'),
  confidential: s__('Notes|Make this comment confidential'),
  confidentialVisibility: s__('Notes|Confidential comments are only visible to project members'),
  discussionThatNeedsResolution: __(
    'Discuss a specific suggestion or question that needs to be resolved.',
  ),
  discussion: __('Discuss a specific suggestion or question.'),
  actionButtonWithNote: __('%{actionText} & %{openOrClose} %{noteable}'),
  actionButton: __('%{openOrClose} %{noteable}'),
  submitButton: {
    startThread: __('Start thread'),
    comment: __('Comment'),
    commentHelp: __('Add a general comment to this %{noteableDisplayName}.'),
  },
};
