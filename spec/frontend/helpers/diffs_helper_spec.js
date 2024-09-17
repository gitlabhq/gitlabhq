import * as diffsHelper from '~/helpers/diffs_helper';

describe('diffs helper', () => {
  function getDiffFile(withOverrides = {}) {
    return {
      parallel_diff_lines: ['line'],
      highlighted_diff_lines: ['line'],
      blob: {
        readable_text: true,
      },
      ...withOverrides,
    };
  }

  describe('hasInlineLines', () => {
    it('is false when the file does not exist', () => {
      expect(diffsHelper.hasInlineLines()).toBe(false);
    });

    it('is false when the file does not have the highlighted_diff_lines property', () => {
      const missingInline = getDiffFile({ highlighted_diff_lines: undefined });

      expect(diffsHelper.hasInlineLines(missingInline)).toBe(false);
    });

    it('is false when the file has zero highlighted_diff_lines', () => {
      const emptyInline = getDiffFile({ highlighted_diff_lines: [] });

      expect(diffsHelper.hasInlineLines(emptyInline)).toBe(false);
    });

    it('is true when the file has at least 1 highlighted_diff_lines', () => {
      expect(diffsHelper.hasInlineLines(getDiffFile())).toBe(true);
    });
  });

  describe('hasParallelLines', () => {
    it('is false when the file does not exist', () => {
      expect(diffsHelper.hasParallelLines()).toBe(false);
    });

    it('is false when the file does not have the parallel_diff_lines property', () => {
      const missingInline = getDiffFile({ parallel_diff_lines: undefined });

      expect(diffsHelper.hasParallelLines(missingInline)).toBe(false);
    });

    it('is false when the file has zero parallel_diff_lines', () => {
      const emptyInline = getDiffFile({ parallel_diff_lines: [] });

      expect(diffsHelper.hasParallelLines(emptyInline)).toBe(false);
    });

    it('is true when the file has at least 1 parallel_diff_lines', () => {
      expect(diffsHelper.hasParallelLines(getDiffFile())).toBe(true);
    });
  });

  describe.each`
    context                              | inline       | parallel     | expected
    ${'only has inline lines'}           | ${['line']}  | ${undefined} | ${true}
    ${'only has parallel lines'}         | ${undefined} | ${['line']}  | ${true}
    ${"doesn't have inline or parallel"} | ${undefined} | ${undefined} | ${false}
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
