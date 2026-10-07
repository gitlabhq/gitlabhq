import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import {
  getLineNumbers,
  getLineChange,
  getLineCode,
  getLinePosition,
  getChangeType,
  getRowPosition,
  findLineRow,
  getNewLinesInRange,
} from '~/rapid_diffs/utils/line_utils';

describe('line_utils', () => {
  afterEach(() => {
    resetHTMLFixture();
  });

  describe('getLineNumbers', () => {
    it('returns [oldLine, newLine] from a row', () => {
      setHTMLFixture(`
        <table><tbody>
          <tr>
            <td data-position="old"><a data-line-number="3"></a></td>
            <td data-position="new"><a data-line-number="5"></a></td>
          </tr>
        </tbody></table>
      `);
      const row = document.querySelector('tr');
      expect(getLineNumbers(row)).toEqual([3, 5]);
    });

    it('returns null for a missing side', () => {
      setHTMLFixture(`
        <table><tbody>
          <tr>
            <td data-position="old"><a data-line-number="3"></a></td>
          </tr>
        </tbody></table>
      `);
      const row = document.querySelector('tr');
      expect(getLineNumbers(row)).toEqual([3, null]);
    });
  });

  describe('getLineChange', () => {
    it('returns change and position from a cell element', () => {
      setHTMLFixture(
        `<table><tbody><tr><td data-position="old" data-change="removed"></td></tr></tbody></table>`,
      );
      const cell = document.querySelector('td');
      expect(getLineChange(cell)).toEqual({ change: 'removed', position: 'old' });
    });
  });

  describe('getLineCode', () => {
    it('builds a code from id and explicit line numbers', () => {
      setHTMLFixture('<table><tbody><tr id="target"></tr></tbody></table>');
      const row = document.querySelector('tr');
      expect(getLineCode({ id: 'abc', row, oldLine: 2, newLine: 4 })).toBe('abc_2_4');
    });

    it('walks siblings to find closest line numbers when lines are null', () => {
      setHTMLFixture(`
        <table><tbody>
          <tr id="target"></tr>
          <tr>
            <td data-position="old"><a data-line-number="7"></a></td>
            <td data-position="new"><a data-line-number="9"></a></td>
          </tr>
        </tbody></table>
      `);
      const row = document.querySelector('#target');
      expect(getLineCode({ id: 'x', row, oldLine: null, newLine: null })).toBe('x_7_9');
    });
  });

  describe('getLinePosition', () => {
    beforeEach(() => {
      setHTMLFixture(`
        <table><tbody>
          <tr>
            <td data-position="old"><a data-line-number="3"></a></td>
            <td data-position="new"><a data-line-number="5"></a></td>
          </tr>
        </tbody></table>
      `);
    });

    it('returns both lines when no side given', () => {
      const row = document.querySelector('tr');
      expect(getLinePosition(row, undefined)).toEqual({ old_line: 3, new_line: 5 });
    });

    it('returns only old_line when side is old', () => {
      const row = document.querySelector('tr');
      expect(getLinePosition(row, 'old')).toEqual({ old_line: 3, new_line: null });
    });

    it('returns only new_line when side is new', () => {
      const row = document.querySelector('tr');
      expect(getLinePosition(row, 'new')).toEqual({ old_line: null, new_line: 5 });
    });
  });

  describe('getChangeType', () => {
    it('returns "new" for a row with an added cell', () => {
      setHTMLFixture(`<table><tbody><tr><td data-change="added"></td></tr></tbody></table>`);
      expect(getChangeType(document.querySelector('tr'))).toBe('new');
    });

    it('returns "old" for a row with a removed cell', () => {
      setHTMLFixture(`<table><tbody><tr><td data-change="removed"></td></tr></tbody></table>`);
      expect(getChangeType(document.querySelector('tr'))).toBe('old');
    });

    it('returns null for an unchanged row', () => {
      setHTMLFixture(`<table><tbody><tr><td></td></tr></tbody></table>`);
      expect(getChangeType(document.querySelector('tr'))).toBeNull();
    });

    it('returns type for the given side only when both sides are changed', () => {
      setHTMLFixture(`
        <table><tbody><tr>
          <td data-position="old" data-change="removed"></td>
          <td data-position="new" data-change="added"></td>
        </tr></tbody></table>
      `);
      const row = document.querySelector('tr');
      expect(getChangeType(row, 'old')).toBe('old');
      expect(getChangeType(row, 'new')).toBe('new');
    });

    it('returns null for a side with no change even when the other side is changed', () => {
      setHTMLFixture(`
        <table><tbody><tr>
          <td data-position="old" data-change="removed"></td>
          <td data-position="new"></td>
        </tr></tbody></table>
      `);
      expect(getChangeType(document.querySelector('tr'), 'new')).toBeNull();
    });
  });

  describe('getRowPosition', () => {
    it('returns both line numbers and null type for an unchanged row', () => {
      setHTMLFixture(`
        <table><tbody><tr>
          <td data-position="old"><a data-line-number="3"></a></td>
          <td data-position="new"><a data-line-number="5"></a></td>
        </tr></tbody></table>
      `);
      expect(getRowPosition(document.querySelector('tr'), undefined)).toEqual({
        old_line: 3,
        new_line: 5,
        type: null,
      });
    });

    it('returns only the side line number and type for a changed row', () => {
      setHTMLFixture(`
        <table><tbody><tr>
          <td data-position="old" data-change="removed"><a data-line-number="3"></a></td>
          <td data-position="new" data-change="added"><a data-line-number="5"></a></td>
        </tr></tbody></table>
      `);
      expect(getRowPosition(document.querySelector('tr'), 'old')).toEqual({
        old_line: 3,
        new_line: null,
        type: 'old',
      });
    });
  });

  describe('getNewLinesInRange', () => {
    const range = (start, end) => ({
      start: { old_line: null, new_line: start },
      end: { old_line: null, new_line: end },
    });
    const newRow = (line, content) =>
      `<tr data-hunk-lines><td data-position="new"><a data-line-number="${line}"></a><pre>${content}</pre></td></tr>`;
    const getTable = () => document.querySelector('table');

    it('returns the new-side lines of the range with its first and last line', () => {
      setHTMLFixture(
        `<table><tbody>${newRow(3, 'line three')}${newRow(4, 'line four')}${newRow(5, 'line five')}</tbody></table>`,
      );

      expect(getNewLinesInRange(getTable(), range(3, 5))).toEqual({
        lines: ['line three', 'line four', 'line five'],
        start: 3,
        end: 5,
      });
    });

    it('returns content of the added side for a changed line', () => {
      setHTMLFixture(`
        <table><tbody>
          <tr data-hunk-lines>
            <td data-position="old" data-change="removed"><a data-line-number="3"></a><pre>old content</pre></td>
            <td data-position="new" data-change="added"><a data-line-number="3"></a><pre>new content</pre></td>
          </tr>
        </tbody></table>
      `);

      const lineRange = { start: { old_line: 3, new_line: 3 }, end: { old_line: 3, new_line: 3 } };
      expect(getNewLinesInRange(getTable(), lineRange).lines).toEqual(['new content']);
    });

    it('strips CR and LF from line content', () => {
      setHTMLFixture(`<table><tbody>${newRow(3, 'line\r\nbreak\n')}</tbody></table>`);

      expect(getNewLinesInRange(getTable(), range(3, 3)).lines).toEqual(['linebreak']);
    });

    it('strips new line characters for diff suggestions', () => {
      setHTMLFixture(`<table><tbody>${newRow(3, 'line\r\nbreak\\n')}</tbody></table>`);

      expect(getNewLinesInRange(getTable(), range(3, 3)).lines).toEqual(['linebreak']);
    });

    it('skips non-hunk rows like discussion rows', () => {
      setHTMLFixture(`
        <table><tbody>
          ${newRow(3, 'first')}
          <tr data-discussion-row><td><pre>discussion content</pre></td></tr>
          ${newRow(4, 'second')}
        </tbody></table>
      `);

      expect(getNewLinesInRange(getTable(), range(3, 4)).lines).toEqual(['first', 'second']);
    });

    it('skips removed lines, which are not part of the new file', () => {
      setHTMLFixture(`
        <table><tbody>
          ${newRow(3, 'unchanged')}
          <tr data-hunk-lines>
            <td data-position="old" data-change="removed"><a data-line-number="4"></a><pre>deleted</pre></td>
            <td data-position="new"></td>
          </tr>
          ${newRow(4, 'also unchanged')}
        </tbody></table>
      `);

      expect(getNewLinesInRange(getTable(), range(3, 4)).lines).toEqual([
        'unchanged',
        'also unchanged',
      ]);
    });

    it('starts at the first new-side line when the range starts on a removed line', () => {
      setHTMLFixture(`
        <table><tbody>
          <tr data-hunk-lines>
            <td data-position="old" data-change="removed"><a data-line-number="7"></a><pre>deleted</pre></td>
          </tr>
          ${newRow(8, 'added')}
        </tbody></table>
      `);

      const lineRange = {
        start: { old_line: 7, new_line: null },
        end: { old_line: null, new_line: 8 },
      };
      expect(getNewLinesInRange(getTable(), lineRange)).toEqual({
        lines: ['added'],
        start: 8,
        end: 8,
      });
    });

    it('returns null when the range ends on a removed line', () => {
      setHTMLFixture(`
        <table><tbody>
          <tr data-hunk-lines>
            <td data-position="old" data-change="removed"><a data-line-number="3"></a><pre>deleted</pre></td>
          </tr>
        </tbody></table>
      `);

      const lineRange = {
        start: { old_line: 3, new_line: null },
        end: { old_line: 3, new_line: null },
      };
      expect(getNewLinesInRange(getTable(), lineRange)).toBeNull();
    });

    it('returns null when the start line is not rendered', () => {
      setHTMLFixture(`<table><tbody>${newRow(3, 'content')}</tbody></table>`);

      expect(getNewLinesInRange(getTable(), range(99, 99))).toBeNull();
    });

    it('returns null when a hunk header splits the range', () => {
      setHTMLFixture(`
        <table><tbody>
          ${newRow(3, 'before')}
          <tr data-hunk-header><td>@@ -10,5 +10,5 @@</td></tr>
          ${newRow(10, 'after')}
        </tbody></table>
      `);

      expect(getNewLinesInRange(getTable(), range(3, 10))).toBeNull();
    });

    it('returns null when lines in the range are not rendered', () => {
      setHTMLFixture(`<table><tbody>${newRow(3, 'three')}${newRow(5, 'five')}</tbody></table>`);

      expect(getNewLinesInRange(getTable(), range(3, 5))).toBeNull();
    });
  });

  describe('findLineRow', () => {
    beforeEach(() => {
      setHTMLFixture(`
        <table>
          <tbody>
            <tr id="old-row">
              <td data-position="old"><a data-line-number="3"></a></td>
            </tr>
            <tr id="new-row">
              <td data-position="new"><a data-line-number="5"></a></td>
            </tr>
          </tbody>
        </table>
      `);
    });

    it('finds a row by old line number', () => {
      const table = document.querySelector('table');
      expect(findLineRow(table, 3, null)).toBe(document.querySelector('#old-row'));
    });

    it('finds a row by new line number when oldLine is null', () => {
      const table = document.querySelector('table');
      expect(findLineRow(table, null, 5)).toBe(document.querySelector('#new-row'));
    });
  });
});
