import { editor } from 'monaco-editor';
import hcl from '~/ide/lib/languages/hcl';
import { registerLanguages } from '~/ide/utils';

describe('tokenization for .tf files', () => {
  beforeEach(() => {
    registerLanguages(hcl);
  });

  it.each([
    ['// Foo', [[{ language: 'hcl', offset: 0, type: 'comment.hcl' }]]],
    ['/* Bar */', [[{ language: 'hcl', offset: 0, type: 'comment.hcl' }]]],
    ['/*', [[{ language: 'hcl', offset: 0, type: 'comment.hcl' }]]],
    [
      'foo = "bar"',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'string.hcl' },
        ],
      ],
    ],
    [
      'variable "foo" {',
      [
        [
          { language: 'hcl', offset: 0, type: 'type.hcl' },
          { language: 'hcl', offset: 8, type: '' },
          { language: 'hcl', offset: 9, type: 'string.hcl' },
          { language: 'hcl', offset: 14, type: '' },
          { language: 'hcl', offset: 15, type: 'delimiter.curly.hcl' },
        ],
      ],
    ],
    [
      // eslint-disable-next-line no-template-curly-in-string
      '  api_key = "${var.foo}"',
      [
        [
          { language: 'hcl', offset: 0, type: '' },
          { language: 'hcl', offset: 2, type: 'variable.hcl' },
          { language: 'hcl', offset: 9, type: '' },
          { language: 'hcl', offset: 10, type: 'operator.hcl' },
          { language: 'hcl', offset: 11, type: '' },
          { language: 'hcl', offset: 12, type: 'string.hcl' },
          { language: 'hcl', offset: 13, type: 'delimiter.hcl' },
          { language: 'hcl', offset: 15, type: 'keyword.var.hcl' },
          { language: 'hcl', offset: 18, type: 'delimiter.hcl' },
          { language: 'hcl', offset: 19, type: 'variable.hcl' },
          { language: 'hcl', offset: 22, type: 'delimiter.hcl' },
          { language: 'hcl', offset: 23, type: 'string.hcl' },
        ],
      ],
    ],
    [
      'resource "aws_security_group" "firewall" {',
      [
        [
          { language: 'hcl', offset: 0, type: 'type.hcl' },
          { language: 'hcl', offset: 8, type: '' },
          { language: 'hcl', offset: 9, type: 'string.hcl' },
          { language: 'hcl', offset: 29, type: '' },
          { language: 'hcl', offset: 30, type: 'string.hcl' },
          { language: 'hcl', offset: 40, type: '' },
          { language: 'hcl', offset: 41, type: 'delimiter.curly.hcl' },
        ],
      ],
    ],
    [
      '  network_interface {',
      [
        [
          { language: 'hcl', offset: 0, type: '' },
          { language: 'hcl', offset: 2, type: 'identifier.hcl' },
          { language: 'hcl', offset: 20, type: 'delimiter.curly.hcl' },
        ],
      ],
    ],
    [
      'foo = [1, 2, "foo"]',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'delimiter.square.hcl' },
          { language: 'hcl', offset: 7, type: 'number.hcl' },
          { language: 'hcl', offset: 8, type: 'delimiter.hcl' },
          { language: 'hcl', offset: 9, type: '' },
          { language: 'hcl', offset: 10, type: 'number.hcl' },
          { language: 'hcl', offset: 11, type: 'delimiter.hcl' },
          { language: 'hcl', offset: 12, type: '' },
          { language: 'hcl', offset: 13, type: 'string.hcl' },
          { language: 'hcl', offset: 18, type: 'delimiter.square.hcl' },
        ],
      ],
    ],
    [
      'resource "foo" "bar" {}',
      [
        [
          { language: 'hcl', offset: 0, type: 'type.hcl' },
          { language: 'hcl', offset: 8, type: '' },
          { language: 'hcl', offset: 9, type: 'string.hcl' },
          { language: 'hcl', offset: 14, type: '' },
          { language: 'hcl', offset: 15, type: 'string.hcl' },
          { language: 'hcl', offset: 20, type: '' },
          { language: 'hcl', offset: 21, type: 'delimiter.curly.hcl' },
        ],
      ],
    ],
    [
      'foo = "bar"',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'string.hcl' },
        ],
      ],
    ],
    [
      'bar = 7',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'number.hcl' },
        ],
      ],
    ],
    [
      'baz = [1,2,3]',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'delimiter.square.hcl' },
          { language: 'hcl', offset: 7, type: 'number.hcl' },
          { language: 'hcl', offset: 8, type: 'delimiter.hcl' },
          { language: 'hcl', offset: 9, type: 'number.hcl' },
          { language: 'hcl', offset: 10, type: 'delimiter.hcl' },
          { language: 'hcl', offset: 11, type: 'number.hcl' },
          { language: 'hcl', offset: 12, type: 'delimiter.square.hcl' },
        ],
      ],
    ],
    [
      'foo = -12',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'operator.hcl' },
          { language: 'hcl', offset: 7, type: 'number.hcl' },
        ],
      ],
    ],
    [
      'bar = 3.14159',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'number.float.hcl' },
        ],
      ],
    ],
    [
      'foo = true',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'keyword.true.hcl' },
        ],
      ],
    ],
    [
      'foo = false',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'keyword.false.hcl' },
        ],
      ],
    ],
    [
      // eslint-disable-next-line no-template-curly-in-string
      'bar = "${file("bing/bong.txt")}"',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'string.hcl' },
          { language: 'hcl', offset: 7, type: 'delimiter.hcl' },
          { language: 'hcl', offset: 9, type: 'type.hcl' },
          { language: 'hcl', offset: 13, type: 'delimiter.parenthesis.hcl' },
          { language: 'hcl', offset: 14, type: 'string.hcl' },
          { language: 'hcl', offset: 29, type: 'delimiter.parenthesis.hcl' },
          { language: 'hcl', offset: 30, type: 'delimiter.hcl' },
          { language: 'hcl', offset: 31, type: 'string.hcl' },
        ],
      ],
    ],
    [
      'a = 1e-10',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 1, type: '' },
          { language: 'hcl', offset: 2, type: 'operator.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'number.float.hcl' },
        ],
      ],
    ],
    [
      'b = 1e+10',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 1, type: '' },
          { language: 'hcl', offset: 2, type: 'operator.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'number.float.hcl' },
        ],
      ],
    ],
    [
      'c = 1e10',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 1, type: '' },
          { language: 'hcl', offset: 2, type: 'operator.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'number.float.hcl' },
        ],
      ],
    ],
    [
      'd = 1.2e-10',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 1, type: '' },
          { language: 'hcl', offset: 2, type: 'operator.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'number.float.hcl' },
        ],
      ],
    ],
    [
      'e = 1.2e+10',
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 1, type: '' },
          { language: 'hcl', offset: 2, type: 'operator.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'number.float.hcl' },
        ],
      ],
    ],
    [
      `  foo = <<-EOF
  bar
  EOF`,
      [
        [
          { language: 'hcl', offset: 0, type: '' },
          { language: 'hcl', offset: 2, type: 'variable.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'operator.hcl' },
          { language: 'hcl', offset: 7, type: '' },
          { language: 'hcl', offset: 8, type: 'string.heredoc.delimiter.hcl' },
        ],
        [{ language: 'hcl', offset: 0, type: 'string.heredoc.hcl' }],
        [
          { language: 'hcl', offset: 0, type: 'string.heredoc.hcl' },
          { language: 'hcl', offset: 2, type: 'string.heredoc.delimiter.hcl' },
        ],
      ],
    ],
    [
      `foo = <<-EOF
bar
EOF`,
      [
        [
          { language: 'hcl', offset: 0, type: 'variable.hcl' },
          { language: 'hcl', offset: 3, type: '' },
          { language: 'hcl', offset: 4, type: 'operator.hcl' },
          { language: 'hcl', offset: 5, type: '' },
          { language: 'hcl', offset: 6, type: 'string.heredoc.delimiter.hcl' },
        ],
        [{ language: 'hcl', offset: 0, type: 'string.heredoc.hcl' }],
        [{ language: 'hcl', offset: 0, type: 'string.heredoc.delimiter.hcl' }],
      ],
    ],
  ])('%s', (string, tokens) => {
    expect(editor.tokenize(string, 'hcl')).toEqual(tokens);
  });
});
