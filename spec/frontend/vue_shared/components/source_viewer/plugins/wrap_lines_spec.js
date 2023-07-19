import wrapLines from '~/vue_shared/components/source_viewer/plugins/wrap_lines';

describe('Highlight.js plugin for wrapping lines', () => {
  it('mutates the input value by wrapping each line in a div with the correct attributes', () => {
    const inputValue = `// some content`;
    const outputValue = `<div id="LC1" lang="javascript" class="line">${inputValue}</div>`;
    const hljsResultMock = { value: inputValue, language: 'javascript' };

    wrapLines(hljsResultMock);
    expect(hljsResultMock.value).toBe(outputValue);
  });
});
