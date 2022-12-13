import { __ } from '~/locale';

const rulesReg = [
  {
    reg: /^[a-zA-Z0-9\u{00A9}-\u{1f9ff}_]/u,
    msg: __("Name must start with a letter, digit, emoji, or '_'"),
  },
  {
    reg: /^[a-zA-Z0-9\p{Pd}\u{002B}\u{00A9}-\u{1f9ff}_. ]+$/u,
    msg: __("Name can contain only letters, digits, emojis, '_', '.', '+', dashes, or spaces"),
  },
];

/**
 *
 * @param {string} text
 * @returns {string} msg
 */
function checkRules(text) {
  for (const item of rulesReg) {
    if (!item.reg.test(text)) {
      return item.msg;
    }
  }
  return '';
}

export { checkRules };
