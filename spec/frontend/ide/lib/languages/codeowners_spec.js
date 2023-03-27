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
    [
      '^[Section name]',
      [
        [
          { language: 'codeowners', offset: 0, type: 'constant.numeric.codeowners' },
          { language: 'codeowners', offset: 1, type: 'namespace.codeowners' },
        ],
      ],
    ],
    [
      '[Section name][3]',
      [
        [
          { language: 'codeowners', offset: 0, type: 'namespace.codeowners' },
          { language: 'codeowners', offset: 14, type: 'constant.numeric.codeowners' },
        ],
      ],
    ],
    [
      '[Section name][30]',
      [
        [
          { language: 'codeowners', offset: 0, type: 'namespace.codeowners' },
          { language: 'codeowners', offset: 14, type: 'constant.numeric.codeowners' },
        ],
      ],
    ],
    [
      '^[Section name][3]',
      [
        [
          { language: 'codeowners', offset: 0, type: 'constant.numeric.codeowners' },
          { language: 'codeowners', offset: 1, type: 'namespace.codeowners' },
          { language: 'codeowners', offset: 15, type: 'constant.numeric.codeowners' },
        ],
      ],
    ],
    [
      '^[Section-name-test][3]',
      [
        [
          { language: 'codeowners', offset: 0, type: 'constant.numeric.codeowners' },
          { language: 'codeowners', offset: 1, type: 'namespace.codeowners' },
          { language: 'codeowners', offset: 20, type: 'constant.numeric.codeowners' },
        ],
      ],
    ],
    [
      '[Section-name_test]',
      [[{ language: 'codeowners', offset: 0, type: 'namespace.codeowners' }]],
    ],
    [
      '[2 Be or not 2 be][3]',
      [
        [
          { language: 'codeowners', offset: 0, type: 'namespace.codeowners' },
          { language: 'codeowners', offset: 18, type: 'constant.numeric.codeowners' },
        ],
      ],
    ],
  ])('%s', (string, tokens) => {
    expect(editor.tokenize(string, 'codeowners')).toEqual(tokens);
  });
});
