import { __ } from '~/locale';

export const START_RULE = {
  regex: /^[a-zA-Z0-9\u{00A9}-\u{1f9ff}_]/u,
  message: __('Group name must start with a letter, digit, emoji, or underscore.'),
};

export const CONTAINS_RULE = {
  regex: /^[a-zA-Z0-9\p{Pd}\u{00A9}-\u{1f9ff}_. ()]+$/u,
  message: __(
    'Group name can contain only letters, digits, dashes, spaces, dots, underscores, parenthesis, and emojis.',
  ),
};
