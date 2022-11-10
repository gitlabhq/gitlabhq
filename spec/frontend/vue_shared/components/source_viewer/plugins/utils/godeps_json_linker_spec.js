import godepsJsonLinker from '~/vue_shared/components/source_viewer/plugins/utils/godeps_json_linker';

const getInputValue = (dependencyString) =>
  `<span class="hljs-attr">&quot;ImportPath&quot;</span><span class="hljs-punctuation">:</span><span class=""> </span><span class="hljs-string">&quot;${dependencyString}&quot;</span>`;
const getOutputValue = (dependencyString, expectedHref) =>
  `<span class="hljs-attr">&quot;ImportPath&quot;</span><span class="hljs-punctuation">:</span><span class=""> </span><span class="hljs-attr">&quot;<a href="${expectedHref}" target="_blank" rel="nofollow noreferrer noopener">${dependencyString}</a>&quot;</span>`;

describe('Highlight.js plugin for linking Godeps.json dependencies', () => {
  it.each`
    dependency                                      | expectedHref
    ${'gitlab.com/group/project/path'}              | ${'https://gitlab.com/group/project/_/tree/master/path'}
    ${'gitlab.com/group/subgroup/project.git/path'} | ${'https://gitlab.com/group/subgroup/_/tree/master/project.git/path'}
    ${'github.com/docker/docker/pkg/homedir'}       | ${'https://github.com/docker/docker/tree/master/pkg/homedir'}
    ${'golang.org/x/net/http2'}                     | ${'https://godoc.org/golang.org/x/net/http2'}
    ${'gopkg.in/yaml.v1'}                           | ${'https://gopkg.in/yaml.v1'}
  `(
    'mutates the input value by wrapping dependency names in anchors and altering path when needed',
    ({ dependency, expectedHref }) => {
      const inputValue = getInputValue(dependency);
      const outputValue = getOutputValue(dependency, expectedHref);
      const hljsResultMock = { value: inputValue };

      const output = godepsJsonLinker(hljsResultMock);
      expect(output).toBe(outputValue);
    },
  );
});
