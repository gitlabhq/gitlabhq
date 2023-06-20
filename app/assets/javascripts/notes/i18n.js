import { __, s__ } from '~/locale';

export const COMMENT_FORM = {
  GENERIC_UNSUBMITTABLE_NETWORK: __(
    'Your comment could not be submitted! Please check your network connection and try again.',
  ),
  error: __('Your comment could not be submitted because %{reason}.'),
  note: __('Note'),
  comment: __('Comment'),
  internalComment: __('Add internal note'),
  issue: __('issue'),
  startThread: __('Start thread'),
  startInternalThread: __('Start internal thread'),
  mergeRequest: __('merge request'),
  epic: __('epic'),
  bodyPlaceholder: __('Write a comment or drag your files here…'),
  bodyPlaceholderInternal: __('Write an internal note or drag your files here…'),
  internal: s__('Notes|Make this an internal note'),
  internalVisibility: s__(
    'Notes|Internal notes are only visible to members with the role of Reporter or higher',
  ),
  discussionThatNeedsResolution: __(
    'Discuss a specific suggestion or question that needs to be resolved.',
  ),
  internalDiscussionThatNeedsResolution: __(
    'Discuss a specific suggestion or question internally that needs to be resolved.',
  ),
  discussion: __('Discuss a specific suggestion or question.'),
  internalDiscussion: __('Discuss a specific suggestion or question internally.'),
  actionButtonWithNote: __('%{actionText} & %{openOrClose} %{noteable}'),
  actionButton: {
    withNote: {
      reopen: __('%{actionText} & reopen %{noteable}'),
      close: __('%{actionText} & close %{noteable}'),
    },
    withoutNote: {
      reopen: __('Reopen %{noteable}'),
      close: __('Close %{noteable}'),
    },
  },
  submitButton: {
    startThread: __('Start thread'),
    startInternalThread: __('Start internal thread'),
    comment: __('Comment'),
    internalComment: __('Add internal note'),
    commentHelp: __('Add a general comment to this %{noteableDisplayName}.'),
    internalCommentHelp: __('Add a confidential internal note to this %{noteableDisplayName}.'),
  },
  attachmentMsg: s__(
    'Notes|Attachments are sent by email. Attachments over 10 MB are sent as links to your GitLab instance, and only accessible to project members.',
  ),
};

export const EDITED_TEXT = {
  actionWithAuthor: __('%{actionText} %{actionDetail} %{timeago} by %{author}'),
  actionWithoutAuthor: __('%{actionText} %{actionDetail}'),
};

export const UPDATE_COMMENT_FORM = {
  error: __('Your comment could not be updated because %{reason}.'),
  defaultError: __('Something went wrong while editing your comment. Please try again.'),
};
