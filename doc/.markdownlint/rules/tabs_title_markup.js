const { forEachLine, getLineMetadata } = require(`markdownlint-rule-helpers`);

module.exports = {
  names: ['tabs-title-markup'],
  description: 'Incorrect number of colon characters for tag',
  information: new URL('https://docs.gitlab.com/ee/development/documentation/styleguide/#tabs'),
  tags: ['gitlab-docs', 'tabs'],
  function: (params, onError) => {
    // Note the correct number of colons in each tab tag type.
    const wrapperColons = 2;
    const titleColons = 3;

    forEachLine(getLineMetadata(params), (line, lineIndex) => {
      // Get the number of colons in this line.
      const colonCount = [...line].filter((x) => x === ':').length;

      // Throw an error in the case of a mismatch.
      if (
        ((line.includes(':Tabs') || line.includes(':EndTabs')) && colonCount !== wrapperColons) ||
        (line.includes(':TabTitle') && colonCount !== titleColons)
      ) {
        const correctColonCount = line.includes(':TabTitle') ? wrapperColons : titleColons;
        onError({
          lineNumber: lineIndex + 1,
          detail: `Actual: ${colonCount}; Expected: ${correctColonCount}`,
        });
      }
    });
  },
};
