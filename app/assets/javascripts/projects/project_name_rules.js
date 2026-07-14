import { __ } from '~/locale';

export const REQUIRED_RULE = {
  reg: /\S/,
  msg: __('Project name is required.'),
};

export const START_RULE = {
  reg: /^[\p{L}\p{N}\u{00A9}-\u{1f9ff}_]/u,
  msg: __('Project name must start with a letter, digit, basic emoji, or underscore.'),
};

export const CONTAINS_RULE = {
  reg: /^[\p{L}\p{N}\p{Pd}\u{002B}\u{00A9}-\u{1f9ff}_. ]+$/u,
  msg: __(
    'Project name can contain only lowercase or uppercase letters, digits, basic emoji, spaces, dots, underscores, dashes, or pluses.',
  ),
};

const rulesReg = [REQUIRED_RULE, START_RULE, CONTAINS_RULE];

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
