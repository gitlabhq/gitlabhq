import packageJsonLinker from '~/vue_shared/components/source_viewer/plugins/utils/package_json_linker';
import { PACKAGE_JSON_CONTENT } from '../mock_data';

describe('Highlight.js plugin for linking package.json dependencies', () => {
  it('mutates the input value by wrapping dependency names and versions in anchors', () => {
    const inputValue =
      '<span class="hljs-attr">&quot;@babel/core&quot;</span><span class="hljs-punctuation">:</span> <span class="hljs-string">&quot;^7.18.5&quot;</span>';
    const outputValue =
      '<span class="hljs-attr">&quot;<a href="https://npmjs.com/package/@babel/core" target="_blank" rel="nofollow noreferrer noopener">@babel/core</a>&quot;</span>: <span class="hljs-attr">&quot;<a href="https://npmjs.com/package/@babel/core" target="_blank" rel="nofollow noreferrer noopener">^7.18.5</a>&quot;</span>';
    const hljsResultMock = { value: inputValue };

    const output = packageJsonLinker(hljsResultMock, PACKAGE_JSON_CONTENT);
    expect(output).toBe(outputValue);
  });
});
