import { __, s__, sprintf } from '~/locale';

/**
 * Builds the alert message for a rebase request the backend refused.
 *
 * The rebase endpoint answers 403 or 409 with `{ merge_error: '<reason>' }`, for
 * example "Source branch is protected from force push". Only fall back to the
 * generic sentence when no reason was sent.
 *
 * @param { Object } error - the rejected Axios error
 * @returns { string } a user-facing message
 */
export const rebaseFailureMessage = (error) => {
  const mergeError = error?.response?.data?.merge_error;

  if (!mergeError) return __('Failed to rebase. Please try again.');

  return sprintf(s__('mrWidget|Failed to rebase: %{mergeError}.'), {
    // The reasons raised before the rebase is queued carry no trailing period,
    // the lock-timeout one does.
    mergeError: mergeError.replace(/\.$/, ''),
  });
};
