import { wrapLines } from '~/vue_shared/components/source_viewer/utils';

describe('Wrap lines', () => {
  it.each`
    input                                              | output
    ${'line 1'}                                        | ${'<span id="LC1" class="line">line 1</span>'}
    ${'line 1\nline 2'}                                | ${`<span id="LC1" class="line">line 1</span>\n<span id="LC2" class="line">line 2</span>`}
    ${'<span class="hljs-code">line 1\nline 2</span>'} | ${`<span id="LC1" class="hljs-code">line 1\n<span id="LC2" class="line">line 2</span></span>`}
    ${'<span class="hljs-code">```bash'}               | ${'<span id="LC1" class="hljs-code">```bash'}
  `('returns lines wrapped in spans containing line numbers', ({ input, output }) => {
    expect(wrapLines(input)).toBe(output);
  });
});
