import goSumLinker from '~/vue_shared/components/source_viewer/plugins/utils/go_sum_linker';

describe('Highlight.js plugin for linking go.sum dependencies', () => {
  it('mutates the input value by wrapping dependencies and tags in anchors', () => {
    const inputValue =
      '<span class="">cloud.google.com/Go/bigquery v1.0.1/go.mod h1:i/xbL2UlR5RvWAURpBYZTtm/cXjCha9lbfbpx4poX+o=</span>';
    const outputValue =
      '<span class=""><a href="https://pkg.go.dev/cloud.google.com/go/bigquery" target="_blank" rel="nofollow noreferrer noopener">cloud.google.com/Go/bigquery</a> v1.0.1/go.mod h1:<a href="https://sum.golang.org/lookup/cloud.google.com/go/bigquery@v1.0.1" target="_blank" rel="nofollow noreferrer noopener">i/xbL2UlR5RvWAURpBYZTtm/cXjCha9lbfbpx4poX+o=</a></span>';
    const hljsResultMock = { value: inputValue };

    const output = goSumLinker(hljsResultMock);
    expect(output).toBe(outputValue);
  });
});
