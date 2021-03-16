const md5 = require('md5');
const stylelint = require('stylelint');

module.exports.createPropertiesHashmap = (
  ruleRoot,
  result,
  ruleName,
  messages,
  selectorGroups,
  addSelectors,
) => {
  ruleRoot.walkRules((rule) => {
    const selector = rule.selector.replace(/(?:\r\n|\r|\n)/g, ' ');

    if (
      rule &&
      rule.parent &&
      rule.parent.type !== 'atrule' &&
      !(
        selector.includes('-webkit-') ||
        selector.includes('-moz-') ||
        selector.includes('-o-') ||
        selector.includes('-ms-') ||
        selector.includes(':')
      )
    ) {
      let cssArray = [];
      rule.nodes.forEach((property) => {
        const { prop, value } = property;
        if (property && value) {
          const propval = `${prop}${value}${property.important ? '!important' : ''}`;
          cssArray.push(propval);
        }
      });

      cssArray = cssArray.sort();
      const cssContent = cssArray.toString();

      if (cssContent) {
        const hashValue = md5(cssContent);
        const selObj = selectorGroups[hashValue];

        const selectorLine = `${selector} (${
          rule.source.input.file ? `${rule.source.input.file} -` : ''
        }${rule.source.start.line}:${rule.source.start.column})`;

        if (selObj) {
          if (selectorGroups[hashValue].selectors.indexOf(selector) === -1) {
            let lastSelector =
              selectorGroups[hashValue].selectors[selectorGroups[hashValue].selectors.length - 1];

            // So we have nicer formatting if it is the same file, we remove the filename
            lastSelector = lastSelector.replace(`${rule.source.input.file} - `, '');

            if (messages) {
              stylelint.utils.report({
                result,
                ruleName,
                message: messages.expected(selector, lastSelector),
                node: rule,
                word: rule.node,
              });
            }

            if (addSelectors) {
              selectorGroups[hashValue].selectors.push(selectorLine);
            }
          }
        } else if (addSelectors) {
          // eslint-disable-next-line no-param-reassign
          selectorGroups[hashValue] = {
            selectors: [selectorLine],
          };
        }
      }
    }
  });
};
