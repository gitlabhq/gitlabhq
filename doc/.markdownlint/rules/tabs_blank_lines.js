const { forEachLine, getLineMetadata, isBlankLine } = require(`markdownlint-rule-helpers`);

module.exports = {
  names: ['tabs-blank-lines'],
  description: 'Tab elements must be surrounded by blank lines',
  tags: ['gitlab-docs', 'tabs'],
  function: (params, onError) => {
    const tabElements = ['::Tabs', '::EndTabs', ':::TabTitle'];
    forEachLine(getLineMetadata(params), (line, lineIndex) => {
      const lineHasTab = tabElements.includes(line.split(' ')[0]);
      const prevLine = params.lines[lineIndex - 1];
      const nextLine = params.lines[lineIndex + 1];

      if (lineHasTab && (!isBlankLine(prevLine) || !isBlankLine(nextLine))) {
        onError({
          lineNumber: lineIndex + 1,
        });
      }
    });
  },
};
