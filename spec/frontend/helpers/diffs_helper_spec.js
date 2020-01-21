import * as diffsHelper from '~/helpers/diffs_helper';

describe('diffs helper', () => {
  function getDiffFile(withOverrides = {}) {
    return {
      parallel_diff_lines: ['line'],
      highlighted_diff_lines: ['line'],
      blob: {
        readable_text: 'text',
      },
      ...withOverrides,
    };
  }

  describe('hasInlineLines', () => {
    it('is false when the file does not exist', () => {
      expect(diffsHelper.hasInlineLines()).toBeFalsy();
    });

    it('is false when the file does not have the highlighted_diff_lines property', () => {
      const missingInline = getDiffFile({ highlighted_diff_lines: undefined });

      expect(diffsHelper.hasInlineLines(missingInline)).toBeFalsy();
    });

    it('is false when the file has zero highlighted_diff_lines', () => {
      const emptyInline = getDiffFile({ highlighted_diff_lines: [] });

      expect(diffsHelper.hasInlineLines(emptyInline)).toBeFalsy();
    });

    it('is true when the file has at least 1 highlighted_diff_lines', () => {
      expect(diffsHelper.hasInlineLines(getDiffFile())).toBeTruthy();
    });
  });

  describe('hasParallelLines', () => {
    it('is false when the file does not exist', () => {
      expect(diffsHelper.hasParallelLines()).toBeFalsy();
    });

    it('is false when the file does not have the parallel_diff_lines property', () => {
      const missingInline = getDiffFile({ parallel_diff_lines: undefined });

      expect(diffsHelper.hasParallelLines(missingInline)).toBeFalsy();
    });

    it('is false when the file has zero parallel_diff_lines', () => {
      const emptyInline = getDiffFile({ parallel_diff_lines: [] });

      expect(diffsHelper.hasParallelLines(emptyInline)).toBeFalsy();
    });

    it('is true when the file has at least 1 parallel_diff_lines', () => {
      expect(diffsHelper.hasParallelLines(getDiffFile())).toBeTruthy();
    });
  });

  describe('isSingleViewStyle', () => {
    it('is true when the file has at least 1 inline line but no parallel lines for any reason', () => {
      const noParallelLines = getDiffFile({ parallel_diff_lines: undefined });
      const emptyParallelLines = getDiffFile({ parallel_diff_lines: [] });

      expect(diffsHelper.isSingleViewStyle(noParallelLines)).toBeTruthy();
      expect(diffsHelper.isSingleViewStyle(emptyParallelLines)).toBeTruthy();
    });

    it('is true when the file has at least 1 parallel line but no inline lines for any reason', () => {
      const noInlineLines = getDiffFile({ highlighted_diff_lines: undefined });
      const emptyInlineLines = getDiffFile({ highlighted_diff_lines: [] });

      expect(diffsHelper.isSingleViewStyle(noInlineLines)).toBeTruthy();
      expect(diffsHelper.isSingleViewStyle(emptyInlineLines)).toBeTruthy();
    });

    it('is true when the file does not have any inline lines or parallel lines for any reason', () => {
      const noLines = getDiffFile({
        highlighted_diff_lines: undefined,
        parallel_diff_lines: undefined,
      });
      const emptyLines = getDiffFile({
        highlighted_diff_lines: [],
        parallel_diff_lines: [],
      });

      expect(diffsHelper.isSingleViewStyle(noLines)).toBeTruthy();
      expect(diffsHelper.isSingleViewStyle(emptyLines)).toBeTruthy();
      expect(diffsHelper.isSingleViewStyle()).toBeTruthy();
    });

    it('is false when the file has both inline and parallel lines', () => {
      expect(diffsHelper.isSingleViewStyle(getDiffFile())).toBeFalsy();
    });
  });

  describe.each`
    context                                     | inline       | parallel     | blob                         | expected
    ${'only has inline lines'}                  | ${['line']}  | ${undefined} | ${undefined}                 | ${true}
    ${'only has parallel lines'}                | ${undefined} | ${['line']}  | ${undefined}                 | ${true}
    ${"doesn't have inline, parallel, or blob"} | ${undefined} | ${undefined} | ${undefined}                 | ${true}
    ${'has blob readable text'}                 | ${undefined} | ${undefined} | ${{ readable_text: 'text' }} | ${false}
  `('when hasDiff', ({ context, inline, parallel, blob, expected }) => {
    it(`${context}`, () => {
      const diffFile = getDiffFile({
        highlighted_diff_lines: inline,
        parallel_diff_lines: parallel,
        blob,
      });

      expect(diffsHelper.hasDiff(diffFile)).toEqual(expected);
    });
  });
});
