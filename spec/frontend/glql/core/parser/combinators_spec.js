import {
  tag,
  tagNoCase,
  regex,
  seq,
  alt,
  many,
  optional,
  whitespace,
  token,
} from '~/glql/core/parser/combinators';

describe('Parser combinators', () => {
  describe('tag', () => {
    it('should parse a string successfully', () => {
      const parser = tag('hello');
      const result = parser.run('hello world');
      expect(result).toEqual({
        success: true,
        value: 'hello',
        rest: ' world',
      });
    });

    it('should fail when string does not match', () => {
      const parser = tag('hello');
      const result = parser.run('world');
      expect(result).toEqual({
        success: false,
        expected: 'hello',
        got: 'world',
      });
    });
  });

  describe('tagNoCase', () => {
    it('should parse a string case-insensitively', () => {
      const parser = tagNoCase('hello');
      const result = parser.run('HELLO world');
      expect(result).toEqual({
        success: true,
        value: 'HELLO',
        rest: ' world',
      });
    });

    it('should fail when string does not match', () => {
      const parser = tagNoCase('hello');
      const result = parser.run('world');
      expect(result).toEqual({
        success: false,
        expected: 'hello',
        got: 'world',
      });
    });

    it('should match mixed case strings', () => {
      const parser = tagNoCase('hello');
      const result = parser.run('HeLlO there');
      expect(result).toEqual({
        success: true,
        value: 'HeLlO',
        rest: ' there',
      });
    });

    it('should return the actual input case in the value', () => {
      const parser = tagNoCase('select');
      const result = parser.run('SELECT * FROM table');
      expect(result).toEqual({
        success: true,
        value: 'SELECT',
        rest: ' * FROM table',
      });
    });
  });

  describe('regex', () => {
    it('should parse a regex successfully', () => {
      const parser = regex(/^\d+/, 'number');
      const result = parser.run('123abc');
      expect(result).toEqual({
        success: true,
        value: '123',
        rest: 'abc',
      });
    });

    it('should fail when regex does not match', () => {
      const parser = regex(/^\d+/, 'number');
      const result = parser.run('abc123');
      expect(result).toEqual({
        success: false,
        expected: 'number',
        got: 'abc123',
      });
    });
  });

  describe('seq', () => {
    it('should parse a simple sequence successfully', () => {
      const parser = seq(tag('hello'), tag(' '), tag('world'));
      const result = parser.run('hello world!');
      expect(result).toEqual({
        success: true,
        value: ['hello', ' ', 'world'],
        rest: '!',
      });
    });

    it('should parse a complex sequence with different parser types', () => {
      const parser = seq(
        tag('start'),
        whitespace,
        regex(/^\d+/, 'number'),
        optional(tag('!')),
        many(tag('a')),
      );
      const result = parser.run('start 123!aaa end');
      expect(result).toEqual({
        success: true,
        value: ['start', ' ', '123', '!', ['a', 'a', 'a']],
        rest: ' end',
      });
    });

    it('should fail when any parser in the sequence fails', () => {
      const parser = seq(tag('hello'), tag(' '), tag('world'), tag('!'));
      const result = parser.run('hello world');
      expect(result).toEqual({
        success: false,
        expected: '!',
        got: '',
      });
    });

    it('should handle empty input correctly', () => {
      const parser = seq(tag('hello'), tag(' '), tag('world'));
      const result = parser.run('');
      expect(result).toEqual({
        success: false,
        expected: 'hello',
        got: '',
      });
    });
  });

  describe('alt', () => {
    it('should parse alternatives successfully', () => {
      const parser = alt(tag('hello'), tag('hi'), tag('hey'));
      const result = parser.run('hi there');
      expect(result).toEqual({
        success: true,
        value: 'hi',
        rest: ' there',
      });
    });

    it('should try all alternatives and succeed with the first match', () => {
      const parser = alt(
        seq(tag('hello'), tag(' '), tag('world')),
        seq(tag('hi'), tag(' '), tag('there')),
        seq(tag('hey'), tag(' '), tag('you')),
      );
      const result = parser.run('hi there friend');
      expect(result).toEqual({
        success: true,
        value: ['hi', ' ', 'there'],
        rest: ' friend',
      });
    });

    it('should fail when no alternative matches', () => {
      const parser = alt(tag('hello'), tag('hi'), tag('hey'));
      const result = parser.run('greetings');
      expect(result).toEqual({
        success: false,
        expected: 'something to parse',
        got: 'greetings',
      });
    });

    it('should handle complex alternatives with different parser types', () => {
      const parser = alt(
        seq(tag('start'), whitespace, regex(/^\d+/, 'number')),
        seq(tag('begin'), whitespace, many(tag('a'))),
        token(tag('end')),
      );
      const result = parser.run('begin aaa');
      expect(result).toEqual({
        success: true,
        value: ['begin', ' ', ['a', 'a', 'a']],
        rest: '',
      });
    });
  });

  describe('many', () => {
    it('should parse multiple occurrences successfully', () => {
      const parser = many(tag('a'));
      const result = parser.run('aaab');
      expect(result).toEqual({
        success: true,
        value: ['a', 'a', 'a'],
        rest: 'b',
      });
    });

    it('should return an empty array when no matches', () => {
      const parser = many(tag('a'));
      const result = parser.run('bbb');
      expect(result).toEqual({
        success: true,
        value: [],
        rest: 'bbb',
      });
    });

    it('should parse complex repeated patterns', () => {
      const parser = many(seq(tag('('), regex(/^[^)]+/, 'content'), tag(')')));
      const result = parser.run('(hello)(world)(!)extra');
      expect(result).toEqual({
        success: true,
        value: [
          ['(', 'hello', ')'],
          ['(', 'world', ')'],
          ['(', '!', ')'],
        ],
        rest: 'extra',
      });
    });

    it('should handle nested many parsers', () => {
      const parser = many(seq(tag('['), many(regex(/^[^\]]+/, 'item')), tag(']')));
      const result = parser.run('[a][b c][d e f]rest');
      expect(result).toEqual({
        success: true,
        value: [
          ['[', ['a'], ']'],
          ['[', ['b c'], ']'],
          ['[', ['d e f'], ']'],
        ],
        rest: 'rest',
      });
    });

    it('should work with whitespace and tokens', () => {
      const parser = many(token(regex(/^[a-z]+/, 'word')));
      const result = parser.run('  hello   world  !');
      expect(result).toEqual({
        success: true,
        value: ['hello', 'world'],
        rest: '  !',
      });
    });
  });

  describe('optional', () => {
    it('should parse optional element when present', () => {
      const parser = optional(tag('a'));
      const result = parser.run('ab');
      expect(result).toEqual({
        success: true,
        value: 'a',
        rest: 'b',
      });
    });

    it('should return null when optional element is not present', () => {
      const parser = optional(tag('a'));
      const result = parser.run('b');
      expect(result).toEqual({
        success: true,
        value: null,
        rest: 'b',
      });
    });
  });

  describe('Parser', () => {
    it('should map parser results', () => {
      const parser = tag('hello').map((value) => value.toUpperCase());
      const result = parser.run('hello world');
      expect(result).toEqual({
        success: true,
        value: 'HELLO',
        rest: ' world',
      });
    });

    it('should chain parsers', () => {
      const parser = tag('hello').chain((value) => tag(` ${value}`));
      const result = parser.run('hello hello');
      expect(result).toEqual({
        success: true,
        value: ' hello',
        rest: '',
      });
    });
  });

  describe('whitespace', () => {
    it('should parse whitespace successfully', () => {
      const result = whitespace.run('   hello');
      expect(result).toEqual({
        success: true,
        value: '   ',
        rest: 'hello',
      });
    });

    it('should fail when no whitespace is present', () => {
      const result = whitespace.run('hello');
      expect(result).toEqual({
        success: false,
        expected: 'whitespace',
        got: 'hello',
      });
    });

    it('should parse different types of whitespace', () => {
      const result = whitespace.run(' \t\n\rhello');
      expect(result).toEqual({
        success: true,
        value: ' \t\n\r',
        rest: 'hello',
      });
    });
  });

  describe('token', () => {
    it('should parse a token with leading whitespace', () => {
      const parser = token(tag('hello'));
      const result = parser.run('   hello world');
      expect(result).toEqual({
        success: true,
        value: 'hello',
        rest: ' world',
      });
    });

    it('should parse a token without leading whitespace', () => {
      const parser = token(tag('hello'));
      const result = parser.run('hello world');
      expect(result).toEqual({
        success: true,
        value: 'hello',
        rest: ' world',
      });
    });

    it('should fail when the token is not present', () => {
      const parser = token(tag('hello'));
      const result = parser.run('   world');
      expect(result).toEqual({
        success: false,
        expected: 'hello',
        got: 'world',
      });
    });

    it('should work with different types of parsers', () => {
      const parser = token(regex(/^\d+/, 'number'));
      const result = parser.run(' \t\n123abc');
      expect(result).toEqual({
        success: true,
        value: '123',
        rest: 'abc',
      });
    });
  });
});
