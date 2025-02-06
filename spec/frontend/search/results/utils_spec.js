import { highlight } from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import {
  HIGHLIGHT_MARK,
  HIGHLIGHT_HTML_START,
  HIGHLIGHT_HTML_END,
} from '~/search/results/constants';

import {
  initLineHighlight,
  cleanLineAndMark,
  isUnsupportedLanguage,
  highlightSearchTerm,
  markSearchTerm,
} from '~/search/results/utils';

jest.mock('~/vue_shared/components/source_viewer/workers/highlight_utils', () => ({
  highlight: jest.fn(),
}));

describe('Global Search Results Utils', () => {
  beforeEach(() => {
    highlight.mockResolvedValue([{ highlightedContent: 'const highlighted = true;' }]);
  });

  describe('isUnsupportedLanguage', () => {
    it.each([
      ['javascript', false],
      ['unknownLanguage', true],
    ])('correctly identifies if %s language is unsupported', (language, expected) => {
      expect(isUnsupportedLanguage(language)).toBe(expected);
    });
  });

  describe('initLineHighlight', () => {
    it('returns original line for unsupported language', async () => {
      highlight.mockClear();

      const result = await initLineHighlight({
        line: { text: 'const test = true;', highlights: [[6, 8]] },
        language: 'txt',
        fileUrl: 'test.txt',
      });

      expect(result).toBe('const test = true;');
      expect(highlight).not.toHaveBeenCalled();
    });

    it('handles gleam files correctly', async () => {
      await initLineHighlight({
        line: { text: 'const test = true;', highlights: [] },
        language: 'javascript',
        fileUrl: 'test.gleam',
      });

      expect(highlight).toHaveBeenCalledWith(null, 'const test = true;', 'gleam');
    });

    describe('when initLineHighlight returns highlight', () => {
      beforeEach(() => {
        highlight.mockImplementation((_, input) =>
          Promise.resolve([{ highlightedContent: input }]),
        );
      });

      it('calls highlight with correct parameters', async () => {
        const result = await initLineHighlight({
          line: { text: 'const test = true;', highlights: [[6, 9]] },
          language: 'javascript',
          fileUrl: 'test.js',
        });

        expect(result).toBe('const <b class="hll">test</b> = true;');
      });
    });
  });

  describe('highlightSearchTerm', () => {
    it('returns empty string for empty input', () => {
      expect(highlightSearchTerm('')).toBe('');
    });

    it('replaces highlight marks with HTML tags', () => {
      const input = `console${HIGHLIGHT_MARK}log${HIGHLIGHT_MARK}(true);`;
      const expected = `console${HIGHLIGHT_HTML_START}log${HIGHLIGHT_HTML_END}(true);`;

      expect(highlightSearchTerm(input)).toBe(expected);
    });

    it('handles multiple highlights', () => {
      const input = `${HIGHLIGHT_MARK}const${HIGHLIGHT_MARK} test = ${HIGHLIGHT_MARK}true${HIGHLIGHT_MARK};`;
      const expected = `${HIGHLIGHT_HTML_START}const${HIGHLIGHT_HTML_END} test = ${HIGHLIGHT_HTML_START}true${HIGHLIGHT_HTML_END};`;

      expect(highlightSearchTerm(input)).toBe(expected);
    });
  });

  describe('markSearchTerm', () => {
    it('adds highlight marks at correct positions', () => {
      const text = 'foobar test foobar test';
      const highlights = [
        [7, 10],
        [19, 22],
      ];

      const result = cleanLineAndMark({ text, highlights });
      const expected = `foobar ${HIGHLIGHT_MARK}test${HIGHLIGHT_MARK} foobar ${HIGHLIGHT_MARK}test${HIGHLIGHT_MARK}`;

      expect([...result].map((c) => c.charCodeAt(0))).toEqual(
        [...expected].map((c) => c.charCodeAt(0)),
      );
    });

    it('adds single highlight mark at correct position', () => {
      const text = '        return false unless licensed_and_indexing_enabled?\\n';
      const highlights = [[28, 57]];

      const result = cleanLineAndMark({ text, highlights });
      const expected = `        return false unless ${HIGHLIGHT_MARK}licensed_and_indexing_enabled?${HIGHLIGHT_MARK}\\n`;

      expect([...result].map((c) => c.charCodeAt(0))).toEqual(
        [...expected].map((c) => c.charCodeAt(0)),
      );
    });

    it('returns empty string for empty input', () => {
      expect(markSearchTerm()).toBe('');
    });

    it('handles empty highlights array', () => {
      const str = 'const test = true;';

      expect(markSearchTerm(str, [])).toBe(str);
    });
  });
});
