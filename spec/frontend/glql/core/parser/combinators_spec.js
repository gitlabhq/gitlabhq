import {
  str,
  regex,
  seq,
  alt,
  many,
  optional,
  whitespace,
  token,
} from '~/glql/core/parser/combinators';

describe('Parser combinators', () => {
  describe('str', () => {
    it('should parse a string successfully', () => {
      const parser = str('hello');
      const result = parser.run('hello world');
      expect(result).toEqual({
        success: true,
        value: 'hello',
        rest: ' world',
      });
    });

    it('should fail when string does not match', () => {
      const parser = str('hello');
      const result = parser.run('world');
      expect(result).toEqual({
        success: false,
        expected: 'hello',
        got: 'world',
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
      const parser = seq(str('hello'), str(' '), str('world'));
      const result = parser.run('hello world!');
      expect(result).toEqual({
        success: true,
        value: ['hello', ' ', 'world'],
        rest: '!',
      });
    });

    it('should parse a complex sequence with different parser types', () => {
      const parser = seq(
        str('start'),
        whitespace,
        regex(/^\d+/, 'number'),
        optional(str('!')),
        many(str('a')),
      );
      const result = parser.run('start 123!aaa end');
      expect(result).toEqual({
        success: true,
        value: ['start', ' ', '123', '!', ['a', 'a', 'a']],
        rest: ' end',
      });
    });

    it('should fail when any parser in the sequence fails', () => {
      const parser = seq(str('hello'), str(' '), str('world'), str('!'));
      const result = parser.run('hello world');
      expect(result).toEqual({
        success: false,
        expected: '!',
        got: '',
      });
    });

    it('should handle empty input correctly', () => {
      const parser = seq(str('hello'), str(' '), str('world'));
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
      const parser = alt(str('hello'), str('hi'), str('hey'));
      const result = parser.run('hi there');
      expect(result).toEqual({
        success: true,
        value: 'hi',
        rest: ' there',
      });
    });

    it('should try all alternatives and succeed with the first match', () => {
      const parser = alt(
        seq(str('hello'), str(' '), str('world')),
        seq(str('hi'), str(' '), str('there')),
        seq(str('hey'), str(' '), str('you')),
      );
      const result = parser.run('hi there friend');
      expect(result).toEqual({
        success: true,
        value: ['hi', ' ', 'there'],
        rest: ' friend',
      });
    });

    it('should fail when no alternative matches', () => {
      const parser = alt(str('hello'), str('hi'), str('hey'));
      const result = parser.run('greetings');
      expect(result).toEqual({
        success: false,
        expected: 'something to parse',
        got: 'greetings',
      });
    });

    it('should handle complex alternatives with different parser types', () => {
      const parser = alt(
        seq(str('start'), whitespace, regex(/^\d+/, 'number')),
        seq(str('begin'), whitespace, many(str('a'))),
        token(str('end')),
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
      const parser = many(str('a'));
      const result = parser.run('aaab');
      expect(result).toEqual({
        success: true,
        value: ['a', 'a', 'a'],
        rest: 'b',
      });
    });

    it('should return an empty array when no matches', () => {
      const parser = many(str('a'));
      const result = parser.run('bbb');
      expect(result).toEqual({
        success: true,
        value: [],
        rest: 'bbb',
      });
    });

    it('should parse complex repeated patterns', () => {
      const parser = many(seq(str('('), regex(/^[^)]+/, 'content'), str(')')));
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
      const parser = many(seq(str('['), many(regex(/^[^\]]+/, 'item')), str(']')));
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
      const parser = optional(str('a'));
      const result = parser.run('ab');
      expect(result).toEqual({
        success: true,
        value: 'a',
        rest: 'b',
      });
    });

    it('should return null when optional element is not present', () => {
      const parser = optional(str('a'));
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
      const parser = str('hello').map((value) => value.toUpperCase());
      const result = parser.run('hello world');
      expect(result).toEqual({
        success: true,
        value: 'HELLO',
        rest: ' world',
      });
    });

    it('should chain parsers', () => {
      const parser = str('hello').chain((value) => str(` ${value}`));
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
      const parser = token(str('hello'));
      const result = parser.run('   hello world');
      expect(result).toEqual({
        success: true,
        value: 'hello',
        rest: ' world',
      });
    });

    it('should parse a token without leading whitespace', () => {
      const parser = token(str('hello'));
      const result = parser.run('hello world');
      expect(result).toEqual({
        success: true,
        value: 'hello',
        rest: ' world',
      });
    });

    it('should fail when the token is not present', () => {
      const parser = token(str('hello'));
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
