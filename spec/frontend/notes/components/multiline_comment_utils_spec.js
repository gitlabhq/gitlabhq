import {
  getSymbol,
  getStartLineNumber,
  getEndLineNumber,
} from '~/notes/components/multiline_comment_utils';

describe('Multiline comment utilities', () => {
  describe('get start & end line numbers', () => {
    const lineRanges = ['old', 'new', null].map(type => ({
      start: { new_line: 1, old_line: 1, type },
      end: { new_line: 2, old_line: 2, type },
    }));
    it.each`
      lineRange        | start   | end
      ${lineRanges[0]} | ${'-1'} | ${'-2'}
      ${lineRanges[1]} | ${'+1'} | ${'+2'}
      ${lineRanges[2]} | ${'1'}  | ${'2'}
    `('returns line numbers `$start` & `$end`', ({ lineRange, start, end }) => {
      expect(getStartLineNumber(lineRange)).toEqual(start);
      expect(getEndLineNumber(lineRange)).toEqual(end);
    });
  });
  describe('getSymbol', () => {
    it.each`
      type         | result
      ${'new'}     | ${'+'}
      ${'old'}     | ${'-'}
      ${'unused'}  | ${''}
      ${''}        | ${''}
      ${null}      | ${''}
      ${undefined} | ${''}
    `('`$type` returns `$result`', ({ type, result }) => {
      expect(getSymbol(type)).toEqual(result);
    });
  });
});
