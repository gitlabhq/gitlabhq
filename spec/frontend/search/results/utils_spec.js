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
  truncateHtml,
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

    it('handles undefined language', () => {
      expect(isUnsupportedLanguage(undefined)).toBe(true);
    });

    it('handles null language', () => {
      expect(isUnsupportedLanguage(null)).toBe(true);
    });
  });

  describe('initLineHighlight', () => {
    it('returns original line for unsupported language', async () => {
      highlight.mockClear();

      const result = await initLineHighlight({
        line: { text: 'const test = true;', highlights: [[6, 9]] },
        language: 'txt',
        fileUrl: 'test.txt',
      });

      expect(result).toBe('const <b class="hll">test</b> = true;');
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

    it('calls highlight with correct parameters', async () => {
      await initLineHighlight({
        line: { text: 'const test = true;', highlights: [[6, 9]] },
        language: 'javascript',
        fileUrl: 'test.js',
      });

      const expected = `const ${HIGHLIGHT_MARK}test${HIGHLIGHT_MARK} = true;`;
      expect(highlight).toHaveBeenCalled();

      const call = highlight.mock.calls[0];
      expect(call[0]).toBe(null);
      expect([...call[1]].map((c) => c.charCodeAt(0))).toEqual(
        [...expected].map((c) => c.charCodeAt(0)),
      );
      expect(call[2]).toBe('javascript');
    });
  });

  describe('highlightSearchTerm', () => {
    it('returns empty string for empty input', () => {
      expect(highlightSearchTerm('')).toBe('');
    });

    it('returns original string when no highlights present', () => {
      expect(highlightSearchTerm('test string')).toBe('test string');
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

    it('handles consecutive highlights', () => {
      const input = `${HIGHLIGHT_MARK}test${HIGHLIGHT_MARK}${HIGHLIGHT_MARK}string${HIGHLIGHT_MARK}`;
      const expected = `${HIGHLIGHT_HTML_START}test${HIGHLIGHT_HTML_END}${HIGHLIGHT_HTML_START}string${HIGHLIGHT_HTML_END}`;

      expect(highlightSearchTerm(input)).toBe(expected);
    });
  });

  describe('cleanLineAndMark', () => {
    it('adds single highlight mark at correct position', () => {
      const str = 'const testValue = true;\n';
      const highlights = [[6, 14]];

      const result = cleanLineAndMark({ text: str, highlights });
      const expected = `const ${HIGHLIGHT_MARK}testValue${HIGHLIGHT_MARK} = true;`;

      expect([...result].map((c) => c.charCodeAt(0))).toEqual(
        [...expected].map((c) => c.charCodeAt(0)),
      );
    });

    it('returns empty string for empty input', () => {
      expect(cleanLineAndMark()).toBe(undefined);
    });

    it('handles empty highlights array', () => {
      const str = 'const test = true;';

      expect(cleanLineAndMark({ text: str, highlights: [] })).toBe(str);
    });
  });

  describe('markSearchTerm', () => {
    it('adds highlight marks at correct positions', () => {
      const str = 'foobar test foobar test';
      const highlights = [
        [7, 10],
        [19, 23],
      ];

      const result = markSearchTerm(str, highlights);
      const expected = `foobar ${HIGHLIGHT_MARK}test${HIGHLIGHT_MARK} foobar ${HIGHLIGHT_MARK}test${HIGHLIGHT_MARK}`;

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

  describe('truncateHtml', () => {
    it('returns original HTML if it is shorter than maximum length', () => {
      const html = '<span>Short text</span>';
      const text = 'Short text';

      expect(truncateHtml(html, text, [])).toBe(html);
    });

    it('truncates HTML around highlights', () => {
      const longText = `${'A'.repeat(5000)}HIGHLIGHT${'B'.repeat(500)}`;
      const html = `<span>${longText}</span>`;
      const highlights = [[5000, 5008]];

      const result = truncateHtml(html, longText, highlights);

      expect(result).toContain('HIGHLIGHT');
      expect(result.length).toBeLessThan(html.length);
    });

    it('adds ellipsis at both ends when truncating middle', () => {
      const prefix = `PREFIX${'A'.repeat(300)}`;
      const middle = 'HIGHLIGHT';
      const suffix = `${'B'.repeat(3000)}SUFFIX`;
      const longText = prefix + middle + suffix;
      const html = `<span>${longText}</span>`;
      const highlights = [[prefix.length, prefix.length + middle.length]];

      const result = truncateHtml(html, longText, highlights);

      expect(result).toContain('…');
      expect(result).toContain('HIGHLIGHT');
    });

    it('preserves HTML structure when truncating', () => {
      const longText = `${'A'.repeat(500)}HIGHLIGHT${'B'.repeat(500)}`;
      const html = `<div><span class="c1">${longText}</span></div>`;
      const highlights = [[500, 508]];

      const result = truncateHtml(html, longText, highlights);

      expect(result).toContain('<span class="c1">');
      expect(result).toContain('</span>');
      expect(result).toContain('</div>');
    });

    it('handles empty or null input', () => {
      expect(truncateHtml('', '', [])).toBe('');
      expect(truncateHtml(null, '', [])).toBe(null);
    });

    it('maintains all highlight clusters when possible', () => {
      const text1 = `${'A'.repeat(100)}FIRST${'B'.repeat(100)}`;
      const text2 = `${'C'.repeat(100)}'SECOND${'D'.repeat(100)}`;
      const longText = text1 + text2;
      const html = `<span>${longText}</span>`;
      const highlights = [
        [100, 105], // FIRST
        [305, 311], // SECOND
      ];

      const result = truncateHtml(html, longText, highlights);

      expect(result).toContain('FIRST');
      expect(result).toContain('SECOND');
    });
  });
});
