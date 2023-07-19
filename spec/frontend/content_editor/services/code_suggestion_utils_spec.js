import {
  lineOffsetToLangParams,
  langParamsToLineOffset,
  toAbsoluteLineOffset,
  getLines,
  appendNewlines,
} from '~/content_editor/services/code_suggestion_utils';

describe('content_editor/services/code_suggestion_utils', () => {
  describe('lineOffsetToLangParams', () => {
    it.each`
      lineOffset | expected
      ${[0, 0]}  | ${'-0+0'}
      ${[0, 2]}  | ${'-0+2'}
      ${[1, 1]}  | ${'+1+1'}
      ${[-1, 1]} | ${'-1+1'}
    `('converts line offset $lineOffset to lang params $expected', ({ lineOffset, expected }) => {
      expect(lineOffsetToLangParams(lineOffset)).toBe(expected);
    });
  });

  describe('langParamsToLineOffset', () => {
    it.each`
      langParams | expected
      ${'-0+0'}  | ${[-0, 0]}
      ${'-0+2'}  | ${[-0, 2]}
      ${'+1+1'}  | ${[1, 1]}
      ${'-1+1'}  | ${[-1, 1]}
    `('converts lang params $langParams to line offset $expected', ({ langParams, expected }) => {
      expect(langParamsToLineOffset(langParams)).toEqual(expected);
    });
  });

  describe('toAbsoluteLineOffset', () => {
    it('adds line number to line offset', () => {
      expect(toAbsoluteLineOffset([-2, 3], 72)).toEqual([70, 75]);
    });
  });

  describe('getLines', () => {
    it('returns lines from allLines', () => {
      const allLines = ['foo', 'bar', 'baz', 'qux', 'quux'];
      expect(getLines([2, 4], allLines)).toEqual(['bar', 'baz', 'qux']);
    });
  });

  describe('appendNewlines', () => {
    it('appends zero-width space to each line', () => {
      const lines = ['foo', 'bar', 'baz'];
      expect(appendNewlines(lines)).toEqual(['foo\u200b\n', 'bar\u200b\n', 'baz\u200b']);
    });
  });
});
