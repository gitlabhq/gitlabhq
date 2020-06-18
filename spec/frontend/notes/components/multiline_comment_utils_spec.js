import {
  getSymbol,
  getStartLineNumber,
  getEndLineNumber,
} from '~/notes/components/multiline_comment_utils';

describe('Multiline comment utilities', () => {
  describe('getStartLineNumber', () => {
    it.each`
      lineCode        | type     | result
      ${'abcdef_1_1'} | ${'old'} | ${'-1'}
      ${'abcdef_1_1'} | ${'new'} | ${'+1'}
      ${'abcdef_1_1'} | ${null}  | ${'1'}
      ${'abcdef'}     | ${'new'} | ${''}
      ${'abcdef'}     | ${'old'} | ${''}
      ${'abcdef'}     | ${null}  | ${''}
    `('returns line number', ({ lineCode, type, result }) => {
      expect(getStartLineNumber({ start_line_code: lineCode, start_line_type: type })).toEqual(
        result,
      );
    });
  });
  describe('getEndLineNumber', () => {
    it.each`
      lineCode        | type     | result
      ${'abcdef_1_1'} | ${'old'} | ${'-1'}
      ${'abcdef_1_1'} | ${'new'} | ${'+1'}
      ${'abcdef_1_1'} | ${null}  | ${'1'}
      ${'abcdef'}     | ${'new'} | ${''}
      ${'abcdef'}     | ${'old'} | ${''}
      ${'abcdef'}     | ${null}  | ${''}
    `('returns line number', ({ lineCode, type, result }) => {
      expect(getEndLineNumber({ end_line_code: lineCode, end_line_type: type })).toEqual(result);
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
