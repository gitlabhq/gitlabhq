import * as textUtils from '~/lib/utils/text_utility';
import { stubCrypto } from 'helpers/crypto';

describe('text_utility', () => {
  describe('addDelimiter', () => {
    it('should add a delimiter to the given string', () => {
      expect(textUtils.addDelimiter('1234')).toEqual('1,234');
      expect(textUtils.addDelimiter('222222')).toEqual('222,222');
    });

    it('should not add a delimiter if string contains no numbers', () => {
      expect(textUtils.addDelimiter('aaaa')).toEqual('aaaa');
    });
  });

  describe('highCountTrim', () => {
    it('returns 99+ for count >= 100', () => {
      expect(textUtils.highCountTrim(105)).toBe('99+');
      expect(textUtils.highCountTrim(100)).toBe('99+');
    });

    it('returns exact number for count < 100', () => {
      expect(textUtils.highCountTrim(45)).toBe(45);
    });
  });

  describe('humanize', () => {
    it('should remove underscores and uppercase the first letter', () => {
      expect(textUtils.humanize('foo_bar')).toEqual('Foo bar');
    });
    it('should remove underscores and dashes and uppercase the first letter', () => {
      expect(textUtils.humanize('foo_bar-foo', '[_-]')).toEqual('Foo bar foo');
    });
  });

  describe('dasherize', () => {
    it('should replace underscores with dashes', () => {
      expect(textUtils.dasherize('foo_bar_foo')).toEqual('foo-bar-foo');
    });
  });

  describe('capitalizeFirstCharacter', () => {
    it('returns string with first letter capitalized', () => {
      expect(textUtils.capitalizeFirstCharacter('gitlab')).toEqual('Gitlab');
    });

    it('returns empty string when given string is empty', () => {
      expect(textUtils.capitalizeFirstCharacter('')).toEqual('');
    });

    it('returns empty string when given string is invalid', () => {
      expect(textUtils.capitalizeFirstCharacter(undefined)).toEqual('');
    });
  });

  describe('slugify', () => {
    it.each`
      title                                                                                      | input                   | output
      ${'should remove accents and convert to lower case'}                                       | ${'João'}               | ${'jo-o'}
      ${'should replaces whitespaces with hyphens and convert to lower case'}                    | ${'My Input String'}    | ${'my-input-string'}
      ${'should remove trailing whitespace and replace whitespaces within string with a hyphen'} | ${' a new project '}    | ${'a-new-project'}
      ${'should only remove non-allowed special characters'}                                     | ${'test!_pro-ject~'}    | ${'test-_pro-ject'}
      ${'should squash to multiple non-allowed special characters'}                              | ${'test!!!!_pro-ject~'} | ${'test-_pro-ject'}
      ${'should return empty string if only non-allowed characters'}                             | ${'дружба'}             | ${''}
      ${'should squash multiple separators'}                                                     | ${'Test:-)'}            | ${'test'}
      ${'should trim any separators from the beginning and end of the slug'}                     | ${'-Test:-)-'}          | ${'test'}
    `('$title', ({ input, output }) => {
      expect(textUtils.slugify(input)).toBe(output);
    });
  });

  describe('stripHtml', () => {
    it('replaces html tag with the default replacement', () => {
      expect(textUtils.stripHtml('This is a text with <p>html</p>.')).toEqual(
        'This is a text with html.',
      );
    });

    it('replaces html tags with the provided replacement', () => {
      expect(textUtils.stripHtml('This is a text with <p>html</p>.', ' ')).toEqual(
        'This is a text with  html .',
      );
    });

    it('passes through with null string input', () => {
      expect(textUtils.stripHtml(null, ' ')).toEqual(null);
    });

    it('passes through with undefined string input', () => {
      expect(textUtils.stripHtml(undefined, ' ')).toEqual(undefined);
    });
  });

  describe('convertToCamelCase', () => {
    it.each`
      txt                         | result
      ${'a_snake_cased_string'}   | ${'aSnakeCasedString'}
      ${'_leading_underscore'}    | ${'_leadingUnderscore'}
      ${'__leading_underscores'}  | ${'__leadingUnderscores'}
      ${'trailing_underscore_'}   | ${'trailingUnderscore_'}
      ${'trailing_underscores__'} | ${'trailingUnderscores__'}
    `('converts string "$txt" to "$result"', ({ txt, result }) => {
      expect(textUtils.convertToCamelCase(txt)).toBe(result);
    });

    it.each`
      txt
      ${'__withoutMiddleUnderscores__'}
      ${''}
      ${'with spaces'}
      ${'with\nnew\r\nlines'}
      ${'_'}
      ${'___'}
    `('does not modify string "$txt"', ({ txt }) => {
      expect(textUtils.convertToCamelCase(txt)).toBe(txt);
    });
  });

  describe('convertToSnakeCase', () => {
    it.each`
      txt                      | result
      ${'snakeCase'}           | ${'snake_case'}
      ${'snake Case'}          | ${'snake_case'}
      ${'snake case'}          | ${'snake_case'}
      ${'snake_case'}          | ${'snake_case'}
      ${'snakeCasesnake Case'} | ${'snake_casesnake_case'}
      ${'123'}                 | ${'123'}
      ${'123 456'}             | ${'123_456'}
    `('converts string $txt to $result string', ({ txt, result }) => {
      expect(textUtils.convertToSnakeCase(txt)).toEqual(result);
    });
  });

  describe('convertToSentenceCase', () => {
    it('converts Sentence Case to Sentence case', () => {
      expect(textUtils.convertToSentenceCase('Hello World')).toBe('Hello world');
    });
  });

  describe('convertToTitleCase', () => {
    it('converts sentence case to Sentence Case', () => {
      expect(textUtils.convertToTitleCase('hello world')).toBe('Hello World');
    });
  });

  describe('truncate', () => {
    it('returns the original string when str length is less than maxLength', () => {
      const str = 'less than 20 chars';
      expect(textUtils.truncate(str, 20)).toEqual(str);
    });

    it('returns truncated string when str length is more than maxLength', () => {
      const str = 'more than 10 chars';
      expect(textUtils.truncate(str, 10)).toEqual(`${str.substring(0, 10 - 1)}…`);
    });

    it('returns the original string when rendered width is exactly equal to maxWidth', () => {
      const str = 'Exactly 16 chars';
      expect(textUtils.truncate(str, 16)).toEqual(str);
    });
  });

  describe('truncateWidth', () => {
    const clientWidthDescriptor = Object.getOwnPropertyDescriptor(Element.prototype, 'clientWidth');

    beforeAll(() => {
      // Mock measured width of ' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
      Object.defineProperty(Element.prototype, 'clientWidth', {
        value: 431,
        writable: false,
      });
    });

    afterAll(() => {
      Object.defineProperty(Element.prototype, 'clientWidth', clientWidthDescriptor);
    });

    it('returns the original string when rendered width is less than maxWidth', () => {
      const str = '< 80px';
      expect(textUtils.truncateWidth(str)).toEqual(str);
    });

    it('returns truncated string when rendered width is more than maxWidth', () => {
      const str = 'This is wider than 80px';
      expect(textUtils.truncateWidth(str)).toEqual(`${str.substring(0, 10)}…`);
    });

    it('returns the original string when rendered width is exactly equal to maxWidth', () => {
      const str = 'Exactly 159.62962962962965px';
      expect(textUtils.truncateWidth(str, { maxWidth: 159.62962962962965, fontSize: 10 })).toEqual(
        str,
      );
    });
  });

  describe('truncateSha', () => {
    it('shortens SHAs to 8 characters', () => {
      expect(textUtils.truncateSha('verylongsha')).toBe('verylong');
    });

    it('leaves short SHAs as is', () => {
      expect(textUtils.truncateSha('shortsha')).toBe('shortsha');
    });
  });

  describe('convertUnicodeToAscii', () => {
    it('does nothing on an empty string', () => {
      expect(textUtils.convertUnicodeToAscii('')).toBe('');
    });

    it('does nothing on an already ascii string', () => {
      expect(textUtils.convertUnicodeToAscii('The quick brown fox jumps over the lazy dog.')).toBe(
        'The quick brown fox jumps over the lazy dog.',
      );
    });

    it('replaces Unicode characters', () => {
      expect(textUtils.convertUnicodeToAscii('Dĭd söméònê äšk fœŕ Ůnĭċődę?')).toBe(
        'Did soemeone aesk foer Unicode?',
      );

      expect(textUtils.convertUnicodeToAscii("Jürgen's Projekt")).toBe("Juergen's Projekt");
      expect(textUtils.convertUnicodeToAscii('öäüÖÄÜ')).toBe('oeaeueOeAeUe');
    });
  });

  describe('splitCamelCase', () => {
    it('separates a PascalCase word to two', () => {
      expect(textUtils.splitCamelCase('HelloWorld')).toBe('Hello World');
    });
  });

  describe('slugifyWithUnderscore', () => {
    it('should replaces whitespaces with underscore and convert to lower case', () => {
      expect(textUtils.slugifyWithUnderscore('My Input String')).toEqual('my_input_string');
    });
  });

  describe('truncateNamespace', () => {
    it(`should return the root namespace if the namespace only includes one level`, () => {
      expect(textUtils.truncateNamespace('a / b')).toBe('a');
    });

    it(`should return the first 2 namespaces if the namespace includes exactly 2 levels`, () => {
      expect(textUtils.truncateNamespace('a / b / c')).toBe('a / b');
    });

    it(`should return the first and last namespaces, separated by "...", if the namespace includes more than 2 levels`, () => {
      expect(textUtils.truncateNamespace('a / b / c / d')).toBe('a / ... / c');
      expect(textUtils.truncateNamespace('a / b / c / d / e / f / g / h / i')).toBe('a / ... / h');
    });

    it(`should return an empty string for invalid inputs`, () => {
      [undefined, null, 4, {}, true, new Date()].forEach((input) => {
        expect(textUtils.truncateNamespace(input)).toBe('');
      });
    });

    it(`should not alter strings that aren't formatted as namespaces`, () => {
      ['', ' ', '\t', 'a', 'a \\ b'].forEach((input) => {
        expect(textUtils.truncateNamespace(input)).toBe(input);
      });
    });
  });

  describe('hasContent', () => {
    it.each`
      txt                 | result
      ${null}             | ${false}
      ${undefined}        | ${false}
      ${{ an: 'object' }} | ${false}
      ${''}               | ${false}
      ${' \t\r\n'}        | ${false}
      ${'hello'}          | ${true}
    `('returns $result for input $txt', ({ result, txt }) => {
      expect(textUtils.hasContent(txt)).toEqual(result);
    });
  });

  describe('isValidSha1Hash', () => {
    const validSha1Hash = '92d10c15';
    const stringOver40 = new Array(42).join('a');

    it.each`
      hash              | valid
      ${validSha1Hash}  | ${true}
      ${'__characters'} | ${false}
      ${'abc'}          | ${false}
      ${stringOver40}   | ${false}
    `(`returns $valid for $hash`, ({ hash, valid }) => {
      expect(textUtils.isValidSha1Hash(hash)).toBe(valid);
    });
  });

  describe('insertFinalNewline', () => {
    it.each`
      input              | output
      ${'some text'}     | ${'some text\n'}
      ${'some text\n'}   | ${'some text\n'}
      ${'some text\n\n'} | ${'some text\n\n'}
      ${'some\n text'}   | ${'some\n text\n'}
    `('adds a newline if it doesnt already exist for input: $input', ({ input, output }) => {
      expect(textUtils.insertFinalNewline(input)).toBe(output);
    });

    it.each`
      input                  | output
      ${'some text'}         | ${'some text\r\n'}
      ${'some text\r\n'}     | ${'some text\r\n'}
      ${'some text\n'}       | ${'some text\n\r\n'}
      ${'some text\r\n\r\n'} | ${'some text\r\n\r\n'}
      ${'some\r\n text'}     | ${'some\r\n text\r\n'}
    `('works with CRLF newline style; input: $input', ({ input, output }) => {
      expect(textUtils.insertFinalNewline(input, '\r\n')).toBe(output);
    });
  });

  describe('escapeShellString', () => {
    it.each`
      character | input                              | output
      ${'"'}    | ${'";echo "you_shouldnt_run_this'} | ${'\'";echo "you_shouldnt_run_this\''}
      ${'$'}    | ${'$IFS'}                          | ${"'$IFS'"}
      ${'\\'}   | ${'evil-branch-name\\'}            | ${"'evil-branch-name\\'"}
      ${'!'}    | ${'!event'}                        | ${"'!event'"}
    `(
      'should not escape the $character character but wrap in single-quotes',
      ({ input, output }) => {
        expect(textUtils.escapeShellString(input)).toBe(output);
      },
    );

    it("should escape the ' character and wrap in single-quotes", () => {
      expect(textUtils.escapeShellString("fix-'bug-behavior'")).toBe(
        "'fix-'\\''bug-behavior'\\'''",
      );
    });
  });

  describe('limitedCounterWithDelimiter', () => {
    it('returns 1,000+ for count greater than 1000', () => {
      const expectedOutput = '1,000+';

      expect(textUtils.limitedCounterWithDelimiter(1001)).toBe(expectedOutput);
      expect(textUtils.limitedCounterWithDelimiter(2300)).toBe(expectedOutput);
    });

    it('returns exact number for count less than 1000', () => {
      expect(textUtils.limitedCounterWithDelimiter(120)).toBe(120);
    });
  });

  describe('base64EncodeUnicode', () => {
    it('encodes unicode characters', () => {
      expect(textUtils.base64EncodeUnicode('😀')).toBe('8J+YgA==');
    });
  });

  describe('base64DecodeUnicode', () => {
    it('decodes unicode characters', () => {
      expect(textUtils.base64DecodeUnicode('8J+YgA==')).toBe('😀');
    });
  });

  describe('findInvalidBranchNameCharacters', () => {
    const invalidChars = [' ', '~', '^', ':', '?', '*', '[', '..', '@{', '\\', '//'];
    const badBranchName = 'branch-with all these ~ ^ : ? * [ ] \\ // .. @{ } //';
    const goodBranch = 'branch-with-no-errrors';

    it('returns an array of invalid characters in a branch name', () => {
      const chars = textUtils.findInvalidBranchNameCharacters(badBranchName);
      chars.forEach((char) => {
        expect(invalidChars).toContain(char);
      });
    });

    it('returns an empty array with no invalid characters', () => {
      expect(textUtils.findInvalidBranchNameCharacters(goodBranch)).toEqual([]);
    });
  });

  describe('humanizeBranchValidationErrors', () => {
    it.each`
      errors               | message
      ${[' ']}             | ${"Can't contain spaces"}
      ${['?', '//', ' ']}  | ${"Can't contain spaces, ?, //"}
      ${['\\', '[', '..']} | ${"Can't contain \\, [, .."}
    `('returns an $message with $errors', ({ errors, message }) => {
      expect(textUtils.humanizeBranchValidationErrors(errors)).toEqual(message);
    });

    it('returns an empty string with no invalid characters', () => {
      expect(textUtils.humanizeBranchValidationErrors([])).toEqual('');
    });
  });

  describe('stripQuotes', () => {
    it.each`
      inputValue     | outputValue
      ${'"Foo Bar"'} | ${'Foo Bar'}
      ${"'Foo Bar'"} | ${'Foo Bar'}
      ${'FooBar'}    | ${'FooBar'}
      ${"Foo'Bar"}   | ${"Foo'Bar"}
      ${'Foo"Bar'}   | ${'Foo"Bar'}
      ${'Foo Bar'}   | ${'Foo Bar'}
    `(
      'returns string $outputValue when called with string $inputValue',
      ({ inputValue, outputValue }) => {
        expect(textUtils.stripQuotes(inputValue)).toBe(outputValue);
      },
    );
  });

  describe('convertEachWordToTitleCase', () => {
    it.each`
      inputValue   | outputValue
      ${'Foo Bar'} | ${'Foo Bar'}
      ${'Foo bar'} | ${'Foo Bar'}
      ${'foo bar'} | ${'Foo Bar'}
      ${'FOO BAr'} | ${'Foo Bar'}
      ${'FOO BAR'} | ${'Foo Bar'}
      ${'fOO bar'} | ${'Foo Bar'}
    `(
      'returns string $outputValue when called with string $inputValue',
      ({ inputValue, outputValue }) => {
        expect(textUtils.convertEachWordToTitleCase(inputValue)).toBe(outputValue);
      },
    );
  });

  describe('uniquifyString', () => {
    it.each`
      inputStr            | inputArray                       | inputModifier | outputValue
      ${'Foo Bar'}        | ${['Foo Bar']}                   | ${' (copy)'}  | ${'Foo Bar (copy)'}
      ${'Foo Bar'}        | ${['Foo Bar', 'Foo Bar (copy)']} | ${' (copy)'}  | ${'Foo Bar (copy) (copy)'}
      ${'Foo Bar (copy)'} | ${['Foo Bar (copy)']}            | ${' (copy)'}  | ${'Foo Bar (copy) (copy)'}
      ${'Foo Bar'}        | ${['Foo']}                       | ${' (copy)'}  | ${'Foo Bar'}
    `(
      'returns string $outputValue when called with string $inputStr, $inputArray, $inputModifier',
      ({ inputStr, inputArray, inputModifier, outputValue }) => {
        expect(textUtils.uniquifyString(inputStr, inputArray, inputModifier)).toBe(outputValue);
      },
    );
  });

  describe('wildcardMatch', () => {
    it.each`
      pattern                  | str                      | result
      ${'label'}               | ${'label'}               | ${true}
      ${'label'}               | ${'a-label'}             | ${false}
      ${'*label'}              | ${'a-label'}             | ${true}
      ${'label'}               | ${'label-a'}             | ${false}
      ${'label*'}              | ${'label-a'}             | ${true}
      ${'label*'}              | ${'a-label-a'}           | ${false}
      ${'*label'}              | ${'a-label-a'}           | ${false}
      ${'*label*'}             | ${'a-label-a'}           | ${true}
      ${'l*l'}                 | ${'label'}               | ${true}
      ${'!@#$%^&*()-=+/?[]{}'} | ${'!@#$%^&*()-=+/?[]{}'} | ${true}
    `('returns expected result', ({ pattern, str, result }) => {
      expect(textUtils.wildcardMatch(str, pattern)).toBe(result);
    });
  });

  describe('sha256', () => {
    beforeEach(stubCrypto);

    it('returns a sha256 hash', async () => {
      const hash = await textUtils.sha256('How vexingly quick daft zebras jump!');
      expect(hash).toBe('3f7282eed1c3cef3efc993275e9b9cc0cfe85927450d6b0e5d73a2c59663232e');
    });
  });
});
