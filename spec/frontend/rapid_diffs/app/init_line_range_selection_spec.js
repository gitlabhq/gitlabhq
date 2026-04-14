import { defineStore } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { initNewDiscussionToggle } from '~/rapid_diffs/app/init_new_discussions_toggle';
import { initLineRangeSelection } from '~/rapid_diffs/app/init_line_range_selection';
import { lineHighlightingAdapter } from '~/rapid_diffs/adapters/line_highlighting';
import { createLineDiscussionsAdapter } from '~/rapid_diffs/adapters/line_discussions';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';

const useMockDiscussionsStore = defineStore('mockDiscussions', () => {
  function addNewLineDiscussionForm() {}
  function findAllLineDiscussionsForFile() {
    return [];
  }
  return { addNewLineDiscussionForm, findAllLineDiscussionsForFile };
});

describe('initLineRangeSelection', () => {
  let appElement;
  let toggle;

  const getAppElement = () => document.querySelector('[data-app]');
  const getDiffFile = () => document.querySelector('diff-file');

  const mountDiffFile = (fixture, viewer = 'text_inline') => {
    const fileData = { viewer, old_path: 'a.js', new_path: 'a.js' };
    setHTMLFixture(`
      <div data-app>
        <button data-new-discussion-toggle data-click="newDiscussion" hidden></button>
        <diff-file data-file-data='${JSON.stringify(fileData)}'>
          <div>
            ${fixture}
          </div>
        </diff-file>
      </div>
    `);
    appElement = getAppElement();
    toggle = appElement.querySelector('[data-new-discussion-toggle]');
    const parallel = viewer === 'text_parallel';
    const adapters = [
      createLineDiscussionsAdapter({ store: useMockDiscussionsStore(), parallel }),
      lineHighlightingAdapter,
    ];
    appElement.addEventListener(
      'click',
      (event) => {
        const diffFile = event.target.closest('diff-file');
        if (diffFile) diffFile.onClick(event);
      },
      { capture: true },
    );
    getDiffFile().mount({
      adapterConfig: { [viewer]: adapters },
      appData: { oldPath: 'a.js', newPath: 'a.js' },
      unobserve: jest.fn(),
    });
    initNewDiscussionToggle(appElement);
    initLineRangeSelection(appElement);
  };

  const createDragEvent = (type, options = {}) => {
    const event = new Event(type, { bubbles: true });
    event.dataTransfer = { effectAllowed: '', setData: jest.fn(), dropEffect: '' };
    event.clientX = options.clientX || 0;
    event.clientY = options.clientY || 0;
    event.preventDefault = jest.fn();
    return event;
  };

  const hoverRow = (row) => {
    row
      .querySelector('[data-position]')
      .dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
  };

  const hoverCell = (cell) => {
    cell.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
  };

  const startDrag = () => {
    toggle.dispatchEvent(createDragEvent('dragstart'));
  };

  const dragOverRow = (row) => {
    document.elementFromPoint = jest.fn().mockReturnValue(row.querySelector('td'));
    appElement.dispatchEvent(createDragEvent('dragover'));
  };

  const mountAndStartParallelDrag = (fixture, side, row = 0) => {
    mountDiffFile(fixture, 'text_parallel');
    const rows = getDiffFile().querySelectorAll('[data-hunk-lines]');
    hoverCell(rows[row].querySelector(`[data-position="${side}"]`));
    startDrag();
    return rows;
  };

  const endDrag = () => {
    const clickSpy = jest.fn();
    toggle.addEventListener('click', clickSpy);
    toggle.dispatchEvent(createDragEvent('dragend'));
    return clickSpy;
  };

  beforeAll(() => {
    if (!customElements.get('diff-file')) {
      customElements.define('diff-file', DiffFile);
    }
  });

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const inlineLine = (oldLine, newLine, content = '') =>
    `<tr data-hunk-lines>
      <td data-position="old"><a href="/" data-line-number="${oldLine}"></a></td>
      <td data-position="new"><a href="/" data-line-number="${newLine}"></a></td>
      <td>${content}</td>
    </tr>`;

  const parallelLine = (oldLine, newLine, content = '') =>
    `<tr data-hunk-lines>
      <td data-position="old">${oldLine ? `<a href="/" data-line-number="${oldLine}"></a>` : ''}</td>
      <td data-position="old">${content}</td>
      <td data-position="new">${newLine ? `<a href="/" data-line-number="${newLine}"></a>` : ''}</td>
      <td data-position="new">${content}</td>
    </tr>`;

  const parallelChangedLine = ({ old, new: newSide } = {}) => {
    const cell = (side, config) => {
      if (!config) return `<td data-position="${side}"></td><td data-position="${side}"></td>`;
      const [line, change] = Array.isArray(config) ? config : [config];
      const changeAttr = change ? ` data-change="${change}"` : '';
      return `<td data-position="${side}"${changeAttr}><a href="/" data-line-number="${line}"></a></td><td data-position="${side}"${changeAttr}></td>`;
    };
    return `<tr data-hunk-lines>${cell('old', old)}${cell('new', newSide)}</tr>`;
  };

  const inlineHunkHeader = '<tr data-hunk-header><td colspan="2"></td><td>@@ hunk @@</td></tr>';
  const parallelHunkHeader =
    '<tr data-hunk-header><td colspan="2"></td><td colspan="2">@@ hunk @@</td></tr>';

  const table = (...rows) => `<table><tbody>${rows.join('')}</tbody></table>`;

  const inlineFixture = table(
    inlineLine(1, 1),
    inlineLine(2, 2),
    inlineLine(3, 3),
    inlineHunkHeader,
    inlineLine(10, 10),
    inlineLine(11, 11),
  );
  const inlineDiscussionFixture = table(inlineLine(1, 1), inlineLine(2, 2), inlineLine(3, 3));
  const parallelFixture = table(
    parallelLine(1, 1),
    parallelLine(2, 2),
    parallelLine(3, 3),
    parallelHunkHeader,
    parallelLine(10, 10),
    parallelLine(11, 11),
  );
  const parallelDiscussionFixture = table(
    parallelLine(1, 1),
    parallelLine(2, 2),
    parallelLine(3, 3),
  );

  const mountAndStartRowDrag = (fixture, viewer, row = 0) => {
    mountDiffFile(fixture, viewer);
    const rows = getDiffFile().querySelectorAll('[data-hunk-lines]');
    hoverRow(rows[row]);
    startDrag();
    return rows;
  };

  const views = [
    {
      name: 'inline',
      viewer: 'text_inline',
      fixture: inlineFixture,
      discussionFixture: inlineDiscussionFixture,
    },
    {
      name: 'parallel',
      viewer: 'text_parallel',
      fixture: parallelFixture,
      discussionFixture: parallelDiscussionFixture,
    },
  ];

  describe.each(views)('$name view', ({ viewer, fixture, discussionFixture }) => {
    it('sets draggable attribute on toggle', () => {
      mountDiffFile(fixture, viewer);
      expect(toggle.getAttribute('draggable')).toBe('true');
    });

    it('highlights start row on dragstart', () => {
      const rows = mountAndStartRowDrag(fixture, viewer);
      expect(rows[0].dataset.highlight).toBeDefined();
    });

    it('highlights rows during drag', () => {
      const rows = mountAndStartRowDrag(fixture, viewer);
      dragOverRow(rows[1]);

      expect(rows[0].dataset.highlight).toContain('start');
      expect(rows[1].dataset.highlight).toContain('end');
    });

    it('highlights rows across a discussion row', () => {
      const rows = mountAndStartRowDrag(fixture, viewer);
      const tbody = rows[0].closest('tbody');
      const discussionRow = document.createElement('tr');
      discussionRow.dataset.discussionRow = 'true';
      discussionRow.innerHTML = '<td colspan="3">discussion</td>';
      tbody.insertBefore(discussionRow, rows[1]);
      dragOverRow(rows[2]);

      expect(rows[0].dataset.highlight).toContain('start');
      expect(rows[2].dataset.highlight).toContain('end');
    });

    it('does not highlight rows across hunk header boundary', () => {
      const rows = mountAndStartRowDrag(fixture, viewer);
      dragOverRow(rows[3]);

      expect(rows[3].dataset.highlight).toBeUndefined();
    });

    it('clears highlight and triggers click on toggle after drag end', () => {
      const rows = mountAndStartRowDrag(fixture, viewer);
      dragOverRow(rows[2]);

      expect(endDrag()).toHaveBeenCalled();
      expect(getDiffFile().querySelectorAll('[data-highlight]')).toHaveLength(0);
    });

    it('sets single line range for single line drag', () => {
      mountAndStartRowDrag(fixture, viewer);
      endDrag();

      expect(toggle.lineRange.start).toStrictEqual(toggle.lineRange.end);
    });

    it('passes multi-line range to store when selecting unchanged lines', () => {
      const rows = mountAndStartRowDrag(discussionFixture, viewer);
      dragOverRow(rows[2]);
      endDrag();

      const store = useMockDiscussionsStore();
      const { lineRange } = store.addNewLineDiscussionForm.mock.calls[0][0];
      expect(lineRange.start.old_line).not.toEqual(lineRange.end.old_line);
    });

    it('places toggle at end of range when dragging upward', () => {
      const rows = mountAndStartRowDrag(discussionFixture, viewer, 2);
      dragOverRow(rows[0]);
      endDrag();

      expect(toggle.closest('tr')).toBe(rows[2]);
    });
  });

  describe('parallel view', () => {
    it('does not extend selection to a row with empty old side', () => {
      const emptyOldFixture = table(parallelLine(1, 1), parallelLine(null, 2), parallelLine(2, 3));
      const rows = mountAndStartParallelDrag(emptyOldFixture, 'old');
      dragOverRow(rows[1]);

      expect(rows[1].dataset.highlight).toBeUndefined();
    });

    it('highlights gap row with empty old side between selected rows', () => {
      const emptyOldFixture = table(parallelLine(1, 1), parallelLine(null, 2), parallelLine(2, 3));
      const rows = mountAndStartParallelDrag(emptyOldFixture, 'old');
      dragOverRow(rows[2]);

      expect(rows[0].dataset.highlight).toBeDefined();
      expect(rows[1].dataset.highlight).toBeDefined();
      expect(rows[2].dataset.highlight).toBeDefined();
    });

    it('extends selection on the new side across rows that have new line numbers', () => {
      const fixture = table(parallelLine(1, 1), parallelLine(null, 2));
      const rows = mountAndStartParallelDrag(fixture, 'new');
      dragOverRow(rows[1]);

      expect(rows[0].dataset.highlight).toContain('start');
      expect(rows[1].dataset.highlight).toContain('end');
    });

    it('positions toggle on the correct side when landing on an added line', () => {
      const fixture = table(
        parallelChangedLine({ old: 1, new: 1 }),
        parallelChangedLine({ new: [2, 'added'] }),
      );
      const rows = mountAndStartParallelDrag(fixture, 'new');
      dragOverRow(rows[1]);
      endDrag();

      expect(useMockDiscussionsStore().addNewLineDiscussionForm).toHaveBeenCalled();
    });

    it('passes end row position in lineRange when landing on an unchanged line', () => {
      const fixture = table(
        parallelChangedLine({ old: [1, 'removed'] }),
        parallelChangedLine({ old: 2, new: 1 }),
      );
      const rows = mountAndStartParallelDrag(fixture, 'old');
      dragOverRow(rows[1]);
      endDrag();

      const { lineRange } = useMockDiscussionsStore().addNewLineDiscussionForm.mock.calls[0][0];
      expect(lineRange.end.old_line).toBe(2);
      expect(lineRange.end.new_line).toBe(1);
    });

    it('passes side-specific lineRange for changed lines on both sides', () => {
      const fixture = table(
        parallelChangedLine({ old: [1, 'removed'], new: [1, 'added'] }),
        parallelChangedLine({ old: [2, 'removed'], new: [2, 'added'] }),
      );
      const rows = mountAndStartParallelDrag(fixture, 'old');
      dragOverRow(rows[1]);
      endDrag();

      const { lineRange } = useMockDiscussionsStore().addNewLineDiscussionForm.mock.calls[0][0];
      expect(lineRange.end.old_line).toBe(2);
      expect(lineRange.end.new_line).toBeNull();
    });

    it('calls addNewLineDiscussionForm when clicking on an unchanged line', () => {
      const fixture = table(parallelLine(1, 1), parallelLine(2, 2));
      mountDiffFile(fixture, 'text_parallel');
      const rows = getDiffFile().querySelectorAll('[data-hunk-lines]');
      hoverCell(rows[0].querySelector('[data-position="new"]'));
      toggle.click();

      const { lineRange } = useMockDiscussionsStore().addNewLineDiscussionForm.mock.calls[0][0];
      expect(lineRange.end.old_line).toBe(1);
      expect(lineRange.end.new_line).toBe(1);
    });

    it('includes both line numbers when drag ends on an unchanged line', () => {
      const fixture = table(
        parallelChangedLine({ new: [1, 'added'] }),
        parallelChangedLine({ old: 1, new: 2 }),
      );
      const rows = mountAndStartParallelDrag(fixture, 'new');
      dragOverRow(rows[1]);
      endDrag();

      const { lineRange } = useMockDiscussionsStore().addNewLineDiscussionForm.mock.calls[0][0];
      expect(lineRange.end.old_line).toBe(1);
      expect(lineRange.end.new_line).toBe(2);
    });

    it('passes side-specific lineRange for unchanged + changed lines on both sides', () => {
      const fixture = table(
        parallelChangedLine({ old: 1, new: 1 }),
        parallelChangedLine({ old: [2, 'removed'], new: [2, 'added'] }),
      );
      const rows = mountAndStartParallelDrag(fixture, 'new');
      dragOverRow(rows[1]);
      endDrag();

      const { lineRange } = useMockDiscussionsStore().addNewLineDiscussionForm.mock.calls[0][0];
      expect(lineRange.end.old_line).toBeNull();
      expect(lineRange.end.new_line).toBe(2);
    });
  });
});
