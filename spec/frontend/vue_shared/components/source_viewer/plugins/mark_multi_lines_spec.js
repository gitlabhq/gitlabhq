import markMultipleLines from '~/vue_shared/components/source_viewer/plugins/mark_multiple_lines';

describe('Highlight.js plugin for mark multi lines', () => {
  it('mutates the input value by marking multi lines and numbering', () => {
    const inputValue = `<span class="hljs-keyword">FROM</span> alpine:latest<span class="hljs-keyword">COPY</span> . /tmp<span class="hljs-keyword">CMD</span> /tmp/run-app`;
    const hljsResultMock = { value: inputValue, language: 'dockerfile' };
    const lineToMarkersInfo = {
      1: [
        {
          index: 1,
          stepNumber: 2,
          startLine: 1,
          endLine: 2,
        },
        {
          index: 2,
          stepNumber: 3,
          startLine: 1,
          endLine: 1,
        },
      ],
    };

    const wrappedLine = `<span id="TEXT-MARKER2,3-L1" class="inline-section-marker"><span id="TEXT-SPAN-MARKER2" class="inline-item-mark">2</span><span id="TEXT-SPAN-MARKER3" class="inline-item-mark">3</span><span class="hljs-keyword">FROM</span> alpine:latest<span class="hljs-keyword">COPY</span> . /tmp<span class="hljs-keyword">CMD</span> /tmp/run-app</span>`;
    const outputValue = `<div class="line">${wrappedLine}</div>`;

    markMultipleLines(hljsResultMock, lineToMarkersInfo);
    expect(hljsResultMock.value).toBe(outputValue);
  });
});
