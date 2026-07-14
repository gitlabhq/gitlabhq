import { s__ } from '~/locale';

const MIN_PATH_LENGTH = 2;
const FORBIDDEN_SUFFIXES = ['.git', '.atom'];

const REQUIRED_MESSAGE = s__('GroupSettings|Group URL is required.');

const START_RULE = {
  test: (value) => /^[a-zA-Z0-9_.]/.test(value),
  message: s__('GroupSettings|Group URL must start with a letter, digit, underscore, or period.'),
};

const CONTAINS_RULE = {
  test: (value) => /^[a-zA-Z0-9_.-]+$/.test(value),
  message: s__(
    'GroupSettings|Group URL can only contain letters, digits, underscores, periods, and dashes.',
  ),
};

const END_RULE = {
  test: (value) => /[a-zA-Z0-9_-]$/.test(value),
  message: s__('GroupSettings|Group URL must end with a letter, digit, underscore, or dash.'),
};

const SUFFIX_RULE = {
  test: (value) => !FORBIDDEN_SUFFIXES.some((suffix) => value.toLowerCase().endsWith(suffix)),
  message: s__('GroupSettings|Group URL must not end with `.git` or `.atom`.'),
};

const MIN_LENGTH_RULE = {
  test: (value) => value.length >= MIN_PATH_LENGTH,
  message: s__('GroupSettings|Group URL must be at least 2 characters long.'),
};

const PATH_RULES = [START_RULE, CONTAINS_RULE, END_RULE, SUFFIX_RULE, MIN_LENGTH_RULE];

/**
 * Validate a group URL (path) against the required, format, and length rules.
 *
 * Returns the first matching error message, or `null` if the path is valid.
 *
 * @param {string} path
 * @returns {string|null}
 */
export const validateGroupPath = (path) => {
  if (!path) return REQUIRED_MESSAGE;

  for (const rule of PATH_RULES) {
    if (!rule.test(path)) return rule.message;
  }

  return null;
};
