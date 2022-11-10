import gemspecLinker from '~/vue_shared/components/source_viewer/plugins/utils/gemspec_linker';

describe('Highlight.js plugin for linking gemspec dependencies', () => {
  it('mutates the input value by wrapping dependency names in anchors', () => {
    const inputValue =
      's.add_dependency(<span class="hljs-string">&#x27;rugged&#x27;</span>, <span class="hljs-string">&#x27;~&gt; 0.24.0&#x27;</span>)';
    const outputValue =
      's.add_dependency(<span class="hljs-string linked">&#x27;<a href="https://rubygems.org/gems/rugged" target="_blank" rel="nofollow noreferrer noopener">rugged</a>&#x27;</span>, <span class="hljs-string">&#x27;~&gt; 0.24.0&#x27;</span>)';
    const hljsResultMock = { value: inputValue };

    const output = gemspecLinker(hljsResultMock);
    expect(output).toBe(outputValue);
  });
});
