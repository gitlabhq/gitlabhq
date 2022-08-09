import { computeDiff } from '~/ide/lib/diff/diff';

describe('Multi-file editor library diff calculator', () => {
  describe('computeDiff', () => {
    it('returns empty array if no changes', () => {
      const diff = computeDiff('123', '123');

      expect(diff).toEqual([]);
    });

    describe('modified', () => {
      it.each`
        originalContent    | newContent          | lineNumber
        ${'123'}           | ${'1234'}           | ${1}
        ${'123\n123\n123'} | ${'123\n1234\n123'} | ${2}
      `(
        'marks line $lineNumber as added and modified but not removed',
        ({ originalContent, newContent, lineNumber }) => {
          const diff = computeDiff(originalContent, newContent)[0];

          expect(diff.added).toBe(true);
          expect(diff.modified).toBe(true);
          expect(diff.removed).toBeUndefined();
          expect(diff.lineNumber).toBe(lineNumber);
        },
      );
    });

    describe('added', () => {
      it.each`
        originalContent    | newContent               | lineNumber
        ${'123'}           | ${'123\n123'}            | ${1}
        ${'123\n123\n123'} | ${'123\n123\n1234\n123'} | ${3}
      `(
        'marks line $lineNumber as added but not modified and not removed',
        ({ originalContent, newContent, lineNumber }) => {
          const diff = computeDiff(originalContent, newContent)[0];

          expect(diff.added).toBe(true);
          expect(diff.modified).toBeUndefined();
          expect(diff.removed).toBeUndefined();
          expect(diff.lineNumber).toBe(lineNumber);
        },
      );
    });

    describe('removed', () => {
      it.each`
        originalContent    | newContent    | lineNumber | modified
        ${'123'}           | ${''}         | ${1}       | ${undefined}
        ${'123\n123\n123'} | ${'123\n123'} | ${2}       | ${true}
      `(
        'marks line $lineNumber as removed',
        ({ originalContent, newContent, lineNumber, modified }) => {
          const diff = computeDiff(originalContent, newContent)[0];

          expect(diff.added).toBeUndefined();
          expect(diff.modified).toBe(modified);
          expect(diff.removed).toBe(true);
          expect(diff.lineNumber).toBe(lineNumber);
        },
      );
    });

    it('includes line number of change', () => {
      const diff = computeDiff('123', '')[0];

      expect(diff.lineNumber).toBe(1);
    });

    it('includes end line number of change', () => {
      const diff = computeDiff('123', '')[0];

      expect(diff.endLineNumber).toBe(1);
    });

    it('disregards changes for EOL type changes', () => {
      const text1 = 'line1\nline2\nline3\n';
      const text2 = 'line1\r\nline2\r\nline3\r\n';

      expect(computeDiff(text1, text2)).toEqual([]);
      expect(computeDiff(text2, text1)).toEqual([]);
    });
  });
});
