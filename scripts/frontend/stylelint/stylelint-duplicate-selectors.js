const stylelint = require('stylelint');
const utils = require('./stylelint-utils');
const ruleName = 'stylelint-gitlab/duplicate-selectors';

const messages = stylelint.utils.ruleMessages(ruleName, {
  expected: (selector1, selector2) => {
    return `"${selector1}" and "${selector2}" have the same properties.`;
  },
});

module.exports = stylelint.createPlugin(ruleName, function(enabled) {
  if (!enabled) {
    return;
  }

  return function(root, result) {
    const selectorGroups = {};
    utils.createPropertiesHashmap(root, result, ruleName, messages, selectorGroups, true);
  };
});

module.exports.ruleName = ruleName;
module.exports.messages = messages;
