import { __ } from '~/locale';

export const TREE_PAGE_LIMIT = 1000; // the maximum amount of items per page
export const TREE_PAGE_SIZE = 100; // the amount of items to be fetched per (batch) request
export const TREE_INITIAL_FETCH_COUNT = TREE_PAGE_LIMIT / TREE_PAGE_SIZE; // the amount of (batch) requests to make

export const COMMIT_BATCH_SIZE = 25; // we request commit data in batches of 25

export const SECONDARY_OPTIONS_TEXT = __('Cancel');
export const COMMIT_LABEL = __('Commit message');
export const TARGET_BRANCH_LABEL = __('Target branch');
export const TOGGLE_CREATE_MR_LABEL = __('Start a new merge request with these changes');
export const NEW_BRANCH_IN_FORK = __(
  'A new branch will be created in your fork and a new merge request will be started.',
);

export const COMMIT_MESSAGE_SUBJECT_MAX_LENGTH = 52;
export const COMMIT_MESSAGE_BODY_MAX_LENGTH = 72;

export const LIMITED_CONTAINER_WIDTH_CLASS = 'limit-container-width';

export const I18N_COMMIT_DATA_FETCH_ERROR = __('An error occurred while fetching commit data.');
