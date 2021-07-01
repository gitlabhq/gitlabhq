const stylelint = require('stylelint');
const utils = require('./stylelint-utils');
const utilityClasses = require('./utility-classes-map');

const ruleName = 'stylelint-gitlab/utility-classes';

const messages = stylelint.utils.ruleMessages(ruleName, {
  expected: (selector1, selector2) => {
    return `"${selector1}" has the same properties as our BS4 utility class "${selector2}" so please use that instead.`;
  },
});

module.exports = stylelint.createPlugin(ruleName, (enabled) => {
  if (!enabled) {
    return;
  }

  // eslint-disable-next-line consistent-return
  return (root, result) => {
    utils.createPropertiesHashmap(root, result, ruleName, messages, utilityClasses, false);
  };
});

module.exports.ruleName = ruleName;
module.exports.messages = messages;
