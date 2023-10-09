import { __ } from '~/locale';

export const SKELETON_SPINNER_VARIANT = 'spinner';

export const SKELETON_STATE = Object.freeze({
  ERROR: 'error',
  VISIBLE: 'visible',
  HIDDEN: 'hidden',
});

export const DEFAULT_TIMERS = Object.freeze({
  TIMEOUT_MS: 20000,
  CONTENT_WAIT_MS: 500,
});

export const TIMEOUT_ERROR_LABEL = __('Unable to load the page');
export const TIMEOUT_ERROR_MESSAGE = __('Reload the page to try again.');
