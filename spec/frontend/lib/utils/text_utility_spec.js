import * as textUtils from '~/lib/utils/text_utility';

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
  });

  describe('slugify', () => {
    it('should remove accents and convert to lower case', () => {
      expect(textUtils.slugify('João')).toEqual('jo-o');
    });
    it('should replaces whitespaces with hyphens and convert to lower case', () => {
      expect(textUtils.slugify('My Input String')).toEqual('my-input-string');
    });
    it('should remove trailing whitespace and replace whitespaces within string with a hyphen', () => {
      expect(textUtils.slugify(' a new project ')).toEqual('a-new-project');
    });
    it('should only remove non-allowed special characters', () => {
      expect(textUtils.slugify('test!_pro-ject~')).toEqual('test-_pro-ject');
    });
    it('should squash multiple hypens', () => {
      expect(textUtils.slugify('test!!!!_pro-ject~')).toEqual('test-_pro-ject');
    });
    it('should return empty string if only non-allowed characters', () => {
      expect(textUtils.slugify('здрасти')).toEqual('');
    });
    it('should squash multiple separators', () => {
      expect(textUtils.slugify('Test:-)')).toEqual('test');
    });
    it('should trim any separators from the beginning and end of the slug', () => {
      expect(textUtils.slugify('-Test:-)-')).toEqual('test');
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

  describe('getFirstCharacterCapitalized', () => {
    it('returns the first character capitalized, if first character is alphabetic', () => {
      expect(textUtils.getFirstCharacterCapitalized('loremIpsumDolar')).toEqual('L');
      expect(textUtils.getFirstCharacterCapitalized('Sit amit !')).toEqual('S');
    });

    it('returns the first character, if first character is non-alphabetic', () => {
      expect(textUtils.getFirstCharacterCapitalized(' lorem')).toEqual(' ');
      expect(textUtils.getFirstCharacterCapitalized('%#!')).toEqual('%');
    });

    it('returns an empty string, if string is falsey', () => {
      expect(textUtils.getFirstCharacterCapitalized('')).toEqual('');
      expect(textUtils.getFirstCharacterCapitalized(null)).toEqual('');
    });
  });

  describe('truncatePathMiddleToLength', () => {
    it('does not truncate text', () => {
      expect(textUtils.truncatePathMiddleToLength('app/test', 50)).toEqual('app/test');
    });

    it('truncates middle of the path', () => {
      expect(textUtils.truncatePathMiddleToLength('app/test/diff', 13)).toEqual('app/…/diff');
    });

    it('truncates multiple times in the middle of the path', () => {
      expect(textUtils.truncatePathMiddleToLength('app/test/merge_request/diff', 13)).toEqual(
        'app/…/…/diff',
      );
    });

    describe('given a path too long for the maxWidth', () => {
      it.each`
        path          | maxWidth | result
        ${'aa/bb/cc'} | ${1}     | ${'…'}
        ${'aa/bb/cc'} | ${2}     | ${'…'}
        ${'aa/bb/cc'} | ${3}     | ${'…/…'}
        ${'aa/bb/cc'} | ${4}     | ${'…/…'}
        ${'aa/bb/cc'} | ${5}     | ${'…/…/…'}
      `('truncates ($path, $maxWidth) to $result', ({ path, maxWidth, result }) => {
        expect(result.length).toBeLessThanOrEqual(maxWidth);
        expect(textUtils.truncatePathMiddleToLength(path, maxWidth)).toEqual(result);
      });
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
      [undefined, null, 4, {}, true, new Date()].forEach(input => {
        expect(textUtils.truncateNamespace(input)).toBe('');
      });
    });

    it(`should not alter strings that aren't formatted as namespaces`, () => {
      ['', ' ', '\t', 'a', 'a \\ b'].forEach(input => {
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
});
