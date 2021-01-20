import {
  getSymbol,
  getStartLineNumber,
  getEndLineNumber,
  getCommentedLines,
} from '~/notes/components/multiline_comment_utils';

describe('Multiline comment utilities', () => {
  describe('get start & end line numbers', () => {
    const lineRanges = ['old', 'new', null].map((type) => ({
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
  const inlineDiffLines = [{ line_code: '1' }, { line_code: '2' }, { line_code: '3' }];
  const parallelDiffLines = inlineDiffLines.map((line) => ({
    left: { ...line },
    right: { ...line },
  }));

  describe.each`
    view          | diffLines
    ${'inline'}   | ${inlineDiffLines}
    ${'parallel'} | ${parallelDiffLines}
  `('getCommentedLines $view view', ({ diffLines }) => {
    it('returns a default object when `selectedCommentPosition` is not provided', () => {
      expect(getCommentedLines(undefined, diffLines)).toEqual({ startLine: 4, endLine: 4 });
    });
    it('returns an object with startLine and endLine equal to 0', () => {
      const selectedCommentPosition = {
        start: { line_code: '1' },
        end: { line_code: '1' },
      };
      expect(getCommentedLines(selectedCommentPosition, diffLines)).toEqual({
        startLine: 0,
        endLine: 0,
      });
    });
    it('returns an object with startLine and endLine equal to 0 and 1', () => {
      const selectedCommentPosition = {
        start: { line_code: '1' },
        end: { line_code: '2' },
      };
      expect(getCommentedLines(selectedCommentPosition, diffLines)).toEqual({
        startLine: 0,
        endLine: 1,
      });
    });
  });
});
