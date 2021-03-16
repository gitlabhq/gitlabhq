const stylelint = require('stylelint');
const utils = require('./stylelint-utils');

const ruleName = 'stylelint-gitlab/duplicate-selectors';

const messages = stylelint.utils.ruleMessages(ruleName, {
  expected: (selector1, selector2) => {
    return `"${selector1}" and "${selector2}" have the same properties.`;
  },
});

module.exports = stylelint.createPlugin(ruleName, (enabled) => {
  if (!enabled) {
    return;
  }

  // eslint-disable-next-line consistent-return
  return (root, result) => {
    const selectorGroups = {};
    utils.createPropertiesHashmap(root, result, ruleName, messages, selectorGroups, true);
  };
});

module.exports.ruleName = ruleName;
module.exports.messages = messages;
