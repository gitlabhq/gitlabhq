import { highlight } from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import {
  HIGHLIGHT_MARK,
  HIGHLIGHT_HTML_START,
  HIGHLIGHT_HTML_END,
  HIGHLIGHT_CLASSES,
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
    beforeEach(() => {});
    it('returns original line for unsupported language', async () => {
      const blobData = {
        line: { text: 'const test = true;', highlights: [[6, 9]] },
        language: 'txt',
        fileUrl: 'test.txt',
      };

      highlight.mockResolvedValue([{ highlightedContent: cleanLineAndMark(blobData.line) }]);
      const result = await initLineHighlight(blobData);

      expect(result).toBe('const <b class="hll">test</b> = true;');
      expect(highlight).toHaveBeenCalled();
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

      expect(result).toContain('HIGHLIGH');
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

    it.each(HIGHLIGHT_CLASSES)('preserves HTML structure when truncating', (highlightClass) => {
      const longText = `${'A'.repeat(500)}HIGHLIGHT${'B'.repeat(500)}`;
      const html = `<div><span class="${highlightClass}1">${longText}</span></div>`;
      const highlights = [[500, 508]];

      const result = truncateHtml(html, longText, highlights);

      expect(result).toContain(`<span class="${highlightClass}1">`);
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
        [100, 105],
        [305, 311],
      ];

      const result = truncateHtml(html, longText, highlights);

      expect(result).toContain('FIRST');
      expect(result).toContain('SECOND');
    });
  });

  describe('truncateHtml edge cases', () => {
    it('properly handles a single highlight longer than maximum length', () => {
      const prefix = 'PREFIX-';
      const longHighlight = 'HIGHLIGHTED-'.repeat(400);
      const suffix = '-SUFFIX';
      const longText = prefix + longHighlight + suffix;

      const highlightedText = `${prefix}<b class="hll">${longHighlight}</b>${suffix}`;
      const html = `<span class="line">${highlightedText}</span>`;

      const highlightStart = prefix.length;
      const highlightEnd = prefix.length + longHighlight.length;
      const highlights = [[highlightStart, highlightEnd]];

      const result = truncateHtml(html, longText, highlights);

      expect(result.length).toBeLessThan(html.length);

      expect(result).toContain('HIGHLIGHTED-');
      expect(result.length).toBe(3045);

      expect(result).toMatch(/…/);
    });

    it('prperly handle cluster with 3 highlights all longer than limit', () => {
      const longText = `${'A'.repeat(100)}FIRST${'B'.repeat(100)}
      ${'C'.repeat(100)}${'SECOND-'.repeat(600)}${'D'.repeat(100)}
      ${'E'.repeat(100)}${'THIRD-'.repeat(600)}${'F'.repeat(100)}`;
      const html = `<span>${longText}</span>`;
      const highlights = [
        [100, 105],
        [305, 3611],
        [3711, 3716],
      ];

      const result = truncateHtml(html, longText, highlights);

      expect(result).toContain('FIRST');
      expect(result).toContain('SECOND');
      expect(result).not.toContain('THIRD');
      expect(result.length).toBe(3014);
    });

    it('properly handles string with many highlights with no apparent clusters', () => {
      const longText = `
      ${'A'.repeat(100)}${'FIRST-'.repeat(3)}${'B'.repeat(200)}${'C'.repeat(200)}${'SECOND-'.repeat(10)}${'D'.repeat(200)}${'E'.repeat(200)}${'THIRD-'.repeat(8)}${'F'.repeat(200)}${'G'.repeat(200)}${'FOUR-'.repeat(7)}${'H'.repeat(200)}${'I'.repeat(200)}${'FIVE-'.repeat(10)}${'J'.repeat(200)}${'K'.repeat(200)}${'SIX-'.repeat(4)}${'L'.repeat(200)}${'M'.repeat(200)}${'SEVEN-'.repeat(6)}${'N'.repeat(200)}${'O'.repeat(200)}${'EIGHT-'.repeat(3)}${'P'.repeat(200)}${'Q'.repeat(200)}${'NINE-'.repeat(2)}${'R'.repeat(200)}${'S'.repeat(200)}${'TEN-'.repeat(5)}${'T'.repeat(200)}`;
      const html = `<span>${longText}</span>`;
      const highlights = [
        [107, 113],
        [113, 119],
        [119, 125],
        [532, 539],
        [539, 546],
        [546, 553],
        [553, 560],
        [560, 567],
        [567, 574],
        [574, 581],
        [581, 588],
        [588, 595],
        [595, 602],
        [1009, 1015],
        [1015, 1021],
        [1021, 1027],
        [1027, 1033],
        [1033, 1039],
        [1039, 1045],
        [1045, 1051],
        [1051, 1057],
        [1464, 1469],
        [1469, 1474],
        [1474, 1479],
        [1479, 1484],
        [1484, 1489],
        [1489, 1494],
        [1494, 1499],
        [1906, 1911],
        [1911, 1916],
        [1916, 1921],
        [1921, 1926],
        [1926, 1931],
        [1931, 1936],
        [1936, 1941],
        [1941, 1946],
        [1946, 1951],
        [1951, 1956],
        [2363, 2367],
        [2367, 2371],
        [2371, 2375],
        [2375, 2379],
        [2786, 2792],
        [2792, 2798],
        [2798, 2804],
        [2804, 2810],
        [2810, 2816],
        [2816, 2822],
        [3229, 3235],
        [3235, 3241],
        [3241, 3247],
        [3654, 3659],
        [3659, 3664],
        [4071, 4075],
        [4075, 4079],
        [4079, 4083],
        [4083, 4087],
        [4087, 4091],
      ];

      const result = truncateHtml(html, longText, highlights);
      expect(result).toContain('FIRST');
      // this results has too many highlight tags
      // to measure the trim correctly we have
      // to strip away the html tags
      const cleanText = result.replace(/<[^>]*>/g, '');
      expect(cleanText.length).toBe(3001);
    });

    it('properly handles string with NO highlights', () => {
      const longText = `
      ${'A'.repeat(100)}${'FIRST-'.repeat(3)}${'B'.repeat(200)}${'C'.repeat(200)}${'SECOND-'.repeat(10)}${'D'.repeat(200)}${'E'.repeat(200)}${'THIRD-'.repeat(8)}${'F'.repeat(200)}${'G'.repeat(200)}${'FOUR-'.repeat(7)}${'H'.repeat(200)}${'I'.repeat(200)}${'FIVE-'.repeat(10)}${'J'.repeat(200)}${'K'.repeat(200)}${'SIX-'.repeat(4)}${'L'.repeat(200)}${'M'.repeat(200)}${'SEVEN-'.repeat(6)}${'N'.repeat(200)}${'O'.repeat(200)}${'EIGHT-'.repeat(3)}${'P'.repeat(200)}${'Q'.repeat(200)}${'NINE-'.repeat(2)}${'R'.repeat(200)}${'S'.repeat(200)}${'TEN-'.repeat(5)}${'T'.repeat(200)}`;
      const html = `<span>${longText}</span>`;
      const highlights = [];

      const result = truncateHtml(html, longText, highlights);
      expect(result).toContain('FIRST');
      expect(result).toHaveLength(3014);
    });
  });
});
