import { wrapLines } from '~/vue_shared/components/source_viewer/utils';

describe('Wrap lines', () => {
  it.each`
    content                                            | language             | output
    ${'line 1'}                                        | ${'javascript'}      | ${'<span id="LC1" lang="javascript" class="line">line 1</span>'}
    ${'line 1\nline 2'}                                | ${'html'}            | ${`<span id="LC1" lang="html" class="line">line 1</span>\n<span id="LC2" lang="html" class="line">line 2</span>`}
    ${'<span class="hljs-code">line 1\nline 2</span>'} | ${'html'}            | ${`<span id="LC1" lang="html" class="hljs-code">line 1\n<span id="LC2" lang="html" class="line">line 2</span></span>`}
    ${'<span class="hljs-code">```bash'}               | ${'bash'}            | ${'<span id="LC1" lang="bash" class="hljs-code">```bash'}
    ${'<span class="hljs-code">```bash'}               | ${'valid-language1'} | ${'<span id="LC1" lang="valid-language1" class="hljs-code">```bash'}
    ${'<span class="hljs-code">```bash'}               | ${'valid_language2'} | ${'<span id="LC1" lang="valid_language2" class="hljs-code">```bash'}
  `('returns lines wrapped in spans containing line numbers', ({ content, language, output }) => {
    expect(wrapLines(content, language)).toBe(output);
  });

  it.each`
    language
    ${'invalidLanguage>'}
    ${'"invalidLanguage"'}
    ${'<invalidLanguage'}
  `('returns lines safely without XSS language is not valid', ({ language }) => {
    expect(wrapLines('<span class="hljs-code">```bash', language)).toBe(
      '<span id="LC1" lang="" class="hljs-code">```bash',
    );
  });
});
