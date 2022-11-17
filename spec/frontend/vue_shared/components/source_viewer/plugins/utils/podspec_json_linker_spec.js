import podspecJsonLinker from '~/vue_shared/components/source_viewer/plugins/utils/podspec_json_linker';
import { PODSPEC_JSON_CONTENT } from '../mock_data';

describe('Highlight.js plugin for linking podspec_json dependencies', () => {
  it('mutates the input value by wrapping dependency names in anchors', () => {
    const inputValue =
      '<span class="hljs-attr">&quot;AFNetworking/Security&quot;</span><span class="hljs-punctuation">:</span><span class=""> </span><span class="hljs-punctuation">[';
    const outputValue =
      '<span class="hljs-attr">&quot;<a href="https://cocoapods.org/pods/AFNetworking" target="_blank" rel="nofollow noreferrer noopener">AFNetworking/Security</a>&quot;</span><span class="hljs-punctuation">:</span><span class=""> </span><span class="hljs-punctuation">[';
    const hljsResultMock = { value: inputValue };
    const output = podspecJsonLinker(hljsResultMock, PODSPEC_JSON_CONTENT);
    expect(output).toBe(outputValue);
  });
});
