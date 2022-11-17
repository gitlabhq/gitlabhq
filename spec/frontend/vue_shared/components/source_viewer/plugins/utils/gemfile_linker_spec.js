import gemfileLinker from '~/vue_shared/components/source_viewer/plugins/utils/gemfile_linker';

describe('Highlight.js plugin for linking gemfile dependencies', () => {
  it('mutates the input value by wrapping dependency names in anchors', () => {
    const inputValue = 'gem </span><span class="hljs-string">&#39;paranoia&#39;';
    const outputValue =
      'gem </span><span class="hljs-string">&#39;<a href="https://rubygems.org/gems/paranoia" target="_blank" rel="nofollow noreferrer noopener">paranoia</a>&#39;';
    const hljsResultMock = { value: inputValue };

    const output = gemfileLinker(hljsResultMock);
    expect(output).toBe(outputValue);
  });
});
