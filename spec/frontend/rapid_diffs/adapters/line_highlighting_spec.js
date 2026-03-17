import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { lineHighlightingAdapter } from '~/rapid_diffs/adapters/line_highlighting';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';

describe('line highlighting adapter', () => {
  const getDiffFile = () => document.querySelector('diff-file');
  const getHighlightedRows = () => getDiffFile().querySelectorAll('[data-highlight]');

  if (!customElements.get('diff-file')) {
    customElements.define('diff-file', DiffFile);
  }

  beforeEach(() => {
    const fileData = { viewer: 'text_inline', old_path: 'old', new_path: 'new' };
    setHTMLFixture(`
      <diff-file data-file-data='${JSON.stringify(fileData)}'>
        <div>
          <table>
            <thead><tr><td></td><td></td></tr></thead>
            <tbody>
              <tr data-hunk-lines>
                <td data-position="old"><a data-line-number="1"></a></td>
                <td></td>
              </tr>
              <tr data-hunk-lines>
                <td data-position="new"><a data-line-number="1"></a></td>
                <td></td>
              </tr>
              <tr data-hunk-lines>
                <td data-position="old"><a data-line-number="2"></a></td>
                <td></td>
              </tr>
            </tbody>
          </table>
        </div>
      </diff-file>
    `);
    getDiffFile().mount({
      adapterConfig: { text_inline: [lineHighlightingAdapter] },
      appData: {},
      unobserve: jest.fn(),
    });
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('highlights a single line', () => {
    const range = { start: { old_line: 1, new_line: null }, end: { old_line: 1, new_line: null } };
    getDiffFile().trigger('HIGHLIGHT_LINES', range);
    expect(getHighlightedRows()).toHaveLength(1);
    expect(getHighlightedRows()[0].dataset.highlight).toBe('start end');
  });

  it('highlights a range of lines', () => {
    const range = { start: { old_line: 1, new_line: null }, end: { old_line: 2, new_line: null } };
    getDiffFile().trigger('HIGHLIGHT_LINES', range);
    expect(getHighlightedRows()).toHaveLength(3);
    expect(getHighlightedRows()[0].dataset.highlight).toBe('start');
    expect(getHighlightedRows()[1].dataset.highlight).toBe('');
    expect(getHighlightedRows()[2].dataset.highlight).toBe(' end');
  });

  it('clears highlight', () => {
    const range = { start: { old_line: 1, new_line: null }, end: { old_line: 1, new_line: null } };
    getDiffFile().trigger('HIGHLIGHT_LINES', range);
    expect(getHighlightedRows()).toHaveLength(1);
    getDiffFile().trigger('CLEAR_HIGHLIGHT');
    expect(getHighlightedRows()).toHaveLength(0);
  });

  it('highlights a line by new_line position', () => {
    const range = { start: { old_line: null, new_line: 1 }, end: { old_line: null, new_line: 1 } };
    getDiffFile().trigger('HIGHLIGHT_LINES', range);
    expect(getHighlightedRows()).toHaveLength(1);
    expect(getHighlightedRows()[0].querySelector('[data-position="new"]')).not.toBeNull();
  });

  it('does not crash when line range is not found', () => {
    const range = {
      start: { old_line: 999, new_line: null },
      end: { old_line: 999, new_line: null },
    };
    getDiffFile().trigger('HIGHLIGHT_LINES', range);
    expect(getHighlightedRows()).toHaveLength(0);
  });

  it('highlights a cross-side range where end row precedes start row in DOM', () => {
    const range = {
      start: { old_line: 2, new_line: null },
      end: { old_line: null, new_line: 1 },
    };
    getDiffFile().trigger('HIGHLIGHT_LINES', range);
    expect(getHighlightedRows()).toHaveLength(2);
  });

  it('clears previous highlight before applying new one', () => {
    const range1 = {
      start: { old_line: 1, new_line: null },
      end: { old_line: 1, new_line: null },
    };
    const range2 = {
      start: { old_line: 2, new_line: null },
      end: { old_line: 2, new_line: null },
    };
    getDiffFile().trigger('HIGHLIGHT_LINES', range1);
    getDiffFile().trigger('HIGHLIGHT_LINES', range2);
    expect(getHighlightedRows()).toHaveLength(1);
    expect(getHighlightedRows()[0].querySelector('[data-line-number]').dataset.lineNumber).toBe(
      '2',
    );
  });
});
