import { __, s__ } from '~/locale';

const REQUIRED_MESSAGE = s__('Groups|Group name is required.');

export const START_RULE = {
  regex: /^[\p{L}\p{N}\u{00A9}-\u{1f9ff}_]/u,
  message: __('Group name must start with a letter, digit, emoji, or underscore.'),
};

export const CONTAINS_RULE = {
  regex: /^[\p{L}\p{N}\p{Pd}\u{00A9}-\u{1f9ff}_. ()]+$/u,
  message: __(
    'Group name can contain only letters, digits, dashes, spaces, dots, underscores, parenthesis, and emojis.',
  ),
};

export const NAME_RULES = [START_RULE, CONTAINS_RULE];

/**
 * Validate a group name against the required and format rules.
 *
 * Returns the first matching error message, or `null` if the name is valid.
 *
 * @param {string} name
 * @returns {string|null}
 */
export const checkGroupNameRules = (name) => {
  if (!name) return REQUIRED_MESSAGE;

  for (const { regex, message } of NAME_RULES) {
    if (!regex.test(name)) return message;
  }

  return null;
};
