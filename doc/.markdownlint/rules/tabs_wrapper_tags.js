module.exports = {
  names: ['tabs-wrapper-tags'],
  description: 'Unequal number of tab start and end tags',
  information: new URL('https://docs.gitlab.com/ee/development/documentation/styleguide/#tabs'),
  tags: ['gitlab-docs', 'tabs'],
  function: function rule(params, onError) {
    const tabStarts = params.lines.filter((line) => line === '::Tabs');
    const tabEnds = params.lines.filter((line) => line === '::EndTabs');

    if (tabStarts.length !== tabEnds.length) {
      const errorIndex =
        params.lines.indexOf('::Tabs') > 0
          ? params.lines.indexOf('::Tabs')
          : params.lines.indexOf('::EndTabs');
      onError({
        lineNumber: errorIndex + 1,
        detail: `Opening tags: ${tabStarts.length}; Closing tags: ${tabEnds.length}`,
      });
    }
  },
};
