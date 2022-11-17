import wrapChildNodes from '~/vue_shared/components/source_viewer/plugins/wrap_child_nodes';

describe('Highlight.js plugin for wrapping _emitter nodes', () => {
  it('mutates the input value by wrapping each node in a span tag', () => {
    const hljsResultMock = {
      _emitter: {
        rootNode: {
          children: [
            { kind: 'string', children: ['Text 1'] },
            { kind: 'string', children: ['Text 2', { kind: 'comment', children: ['Text 3'] }] },
            { kind: undefined, sublanguage: true, children: ['Text 3 (sublanguage)'] },
            'Text4\nText5',
          ],
        },
      },
    };

    const outputValue = `<span class="hljs-string">Text 1</span><span class="hljs-string"><span class="hljs-string">Text 2</span><span class="hljs-comment">Text 3</span></span><span class="">Text 3 (sublanguage)</span><span class="">Text4</span>\n<span class="">Text5</span>`;

    wrapChildNodes(hljsResultMock);
    expect(hljsResultMock.value).toBe(outputValue);
  });
});
