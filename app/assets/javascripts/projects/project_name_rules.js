import { __ } from '~/locale';

export const START_RULE = {
  reg: /^[a-zA-Z0-9\u{00A9}-\u{1f9ff}_]/u,
  msg: __('Name must start with a letter, digit, emoji, or underscore.'),
};

export const CONTAINS_RULE = {
  reg: /^[a-zA-Z0-9\p{Pd}\u{002B}\u{00A9}-\u{1f9ff}_. ]+$/u,
  msg: __(
    'Name can contain only lowercase or uppercase letters, digits, emoji, spaces, dots, underscores, dashes, or pluses.',
  ),
};

const rulesReg = [START_RULE, CONTAINS_RULE];

/**
 *
 * @param {string} text
 * @returns {string} msg
 */
export const checkRules = (text) => {
  for (const item of rulesReg) {
    if (!item.reg.test(text)) {
      return item.msg;
    }
  }
  return '';
};
