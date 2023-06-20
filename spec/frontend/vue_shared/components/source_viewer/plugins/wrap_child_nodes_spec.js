import wrapChildNodes from '~/vue_shared/components/source_viewer/plugins/wrap_child_nodes';

describe('Highlight.js plugin for wrapping _emitter nodes', () => {
  it('mutates the input value by wrapping each node in a span tag', () => {
    const hljsResultMock = {
      _emitter: {
        rootNode: {
          children: [
            { scope: 'string', children: ['Text 1'] },
            { scope: 'string', children: ['Text 2', { scope: 'comment', children: ['Text 3'] }] },
            { scope: undefined, sublanguage: true, children: ['Text 4 (sublanguage)'] },
            { scope: undefined, sublanguage: undefined, children: ['Text 5'] },
            'Text6\nText7',
          ],
        },
      },
    };

    const outputValue = `<span class="hljs-string">Text 1</span><span class="hljs-string"><span class="hljs-string">Text 2</span><span class="hljs-comment">Text 3</span></span><span class="">Text 4 (sublanguage)</span><span class="">Text 5</span><span class="">Text6</span>\n<span class="">Text7</span>`;

    wrapChildNodes(hljsResultMock);
    expect(hljsResultMock.value).toBe(outputValue);
  });
});
