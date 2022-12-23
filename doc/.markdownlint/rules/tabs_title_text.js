const { globalPath } = require('../require_helper');
const {
  forEachLine,
  getLineMetadata,
  isBlankLine,
} = require(`${globalPath}/markdownlint-rule-helpers`);

module.exports = {
  names: ['tabs-title-text'],
  description: 'Tab without title text',
  information: new URL('https://docs.gitlab.com/ee/development/documentation/styleguide/#tabs'),
  tags: ['gitlab-docs', 'tabs'],
  function: (params, onError) => {
    forEachLine(getLineMetadata(params), (line, lineIndex) => {
      if (!isBlankLine(line) && line.replace(':::TabTitle', '').trim() === '') {
        onError({
          lineNumber: lineIndex + 1,
          detail: 'Expected: :::TabTitle <your title here>; Actual: :::TabTitle',
        });
      }
    });
  },
};
