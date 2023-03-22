import { editor } from 'monaco-editor';
import codeowners from '~/ide/lib/languages/codeowners';
import { registerLanguages } from '~/ide/utils';

describe('tokenization for CODEOWNERS files', () => {
  beforeEach(() => {
    registerLanguages(codeowners);
  });

  it.each([
    ['## Foo bar comment', [[{ language: 'codeowners', offset: 0, type: 'comment.codeowners' }]]],
    [
      '/foo/bar @gsamsa',
      [
        [
          { language: 'codeowners', offset: 0, type: 'regexp.codeowners' },
          { language: 'codeowners', offset: 8, type: 'source.codeowners' },
          { language: 'codeowners', offset: 9, type: 'variable.value.codeowners' },
        ],
      ],
    ],
    ['^[Section name]', [[{ language: 'codeowners', offset: 0, type: 'namespace.codeowners' }]]],
  ])('%s', (string, tokens) => {
    expect(editor.tokenize(string, 'codeowners')).toEqual(tokens);
  });
});
