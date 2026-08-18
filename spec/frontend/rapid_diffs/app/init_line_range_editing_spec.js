import { ref } from 'vue';
import { defineStore } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { initLineRangeEditing } from '~/rapid_diffs/app/init_line_range_editing';
import { lineHighlightingAdapter } from '~/rapid_diffs/adapters/line_highlighting';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';

const useMockStore = defineStore('mockEditingStore', () => {
  const lineRangeEditing = ref(null);
  const commitLineRangeEditing = jest.fn();
  const cancelLineRangeEditing = jest.fn();
  function setEditing(value) {
    lineRangeEditing.value = value;
  }
  return { lineRangeEditing, commitLineRangeEditing, cancelLineRangeEditing, setEditing };
});

describe('initLineRangeEditing', () => {
  let appElement;
  let store;

  const getAppElement = () => document.querySelector('[data-app]');
  const getDiffFile = () => document.querySelector('diff-file');
  const findHandles = () => appElement.querySelectorAll('.rd-line-range-handle');
  const findHandle = (type) => appElement.querySelector(`[data-line-range-handle="${type}"]`);
  const findCancelButton = () => appElement.querySelector('[data-line-range-cancel]');
  const getRows = () => [...getDiffFile().querySelectorAll('[data-hunk-lines]')];
  const highlightedNewLines = () =>
    getRows()
      .filter((row) => row.dataset.highlight !== undefined)
      .map((row) =>
        Number(row.querySelector('[data-position="new"] [data-line-number]').dataset.lineNumber),
      );

  const inlineAdded = (newLine) => `
    <tr data-hunk-lines>
      <td class="rd-line-number rd-line-number-empty" data-position="old" data-change="added"></td>
      <td class="rd-line-number" data-position="new" data-change="added">
        <a class="rd-line-link" data-line-number="${newLine}"></a>
      </td>
      <td class="rd-line-content" data-change="added"><pre class="rd-line-text">line ${newLine}</pre></td>
    </tr>`;

  const parallelAdded = (newLine) => `
    <tr data-hunk-lines>
      <td class="rd-line-number rd-line-number-empty" data-position="old"></td>
      <td class="rd-line-content rd-line-number-empty" data-position="old"></td>
      <td class="rd-line-number" data-position="new" data-change="added">
        <a class="rd-line-link" data-line-number="${newLine}"></a>
      </td>
      <td class="rd-line-content" data-position="new" data-change="added">
        <pre class="rd-line-text">line ${newLine}</pre>
      </td>
    </tr>`;

  const inlineFixture = `<table><tbody>
    ${inlineAdded(5)}${inlineAdded(6)}${inlineAdded(7)}${inlineAdded(8)}
  </tbody></table>`;

  const parallelFixture = `<table><tbody>
    ${parallelAdded(5)}${parallelAdded(6)}${parallelAdded(7)}${parallelAdded(8)}
  </tbody></table>`;

  const newSidePos = (newLine) => ({ old_line: null, new_line: newLine, type: 'new' });
  const editingContext = (startLine, endLine) => ({
    discussion: {
      position: { old_path: 'a.js', new_path: 'a.js' },
      lineChange: { change: 'added', position: 'new' },
    },
    lineRange: { start: newSidePos(startLine), end: newSidePos(endLine) },
  });

  const mount = (fixture = inlineFixture, viewer = 'text_inline') => {
    const fileData = { viewer, old_path: 'a.js', new_path: 'a.js' };
    setHTMLFixture(`
      <div data-app>
        <diff-file id="abc" data-file-data='${JSON.stringify(fileData)}'>
          <div>${fixture}</div>
        </diff-file>
      </div>
    `);
    appElement = getAppElement();
    getDiffFile().mount({
      adapterConfig: { [viewer]: [lineHighlightingAdapter] },
      appData: { oldPath: 'a.js', newPath: 'a.js' },
      unobserve: jest.fn(),
    });
    store = useMockStore();
    initLineRangeEditing(appElement, store);
  };

  const startEditing = async (startLine, endLine) => {
    store.setEditing(editingContext(startLine, endLine));
    await waitForPromises();
  };

  const createDragEvent = (type, options = {}) => {
    const event = new Event(type, { bubbles: true });
    event.dataTransfer = { effectAllowed: '', setData: jest.fn(), dropEffect: '' };
    event.clientX = options.clientX || 0;
    event.clientY = options.clientY || 0;
    event.preventDefault = jest.fn();
    return event;
  };

  const dragHandleToRow = (type, row) => {
    findHandle(type).dispatchEvent(createDragEvent('dragstart'));
    document.elementFromPoint = jest.fn().mockReturnValue(row.querySelector('td'));
    appElement.dispatchEvent(createDragEvent('dragover'));
    findHandle(type).dispatchEvent(createDragEvent('dragend'));
  };

  beforeAll(() => {
    if (!customElements.get('diff-file')) {
      customElements.define('diff-file', DiffFile);
    }
  });

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    mount();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when editing starts', () => {
    beforeEach(() => startEditing(6, 7));

    it('marks the diff file as editing', () => {
      expect(getDiffFile().dataset.lineRangeEditing).toBe('');
    });

    it('renders a start handle, an end handle and a cancel button', () => {
      expect(findHandles()).toHaveLength(2);
      expect(findCancelButton()).not.toBeNull();
    });

    it('renders sprite icons inside the handles and cancel button', () => {
      const iconRef = (el) => el.querySelector('svg use').getAttribute('xlink:href');
      expect(iconRef(findHandle('start'))).toContain('#grip');
      expect(iconRef(findHandle('end'))).toContain('#grip');
      expect(iconRef(findCancelButton())).toContain('#close');
    });

    it('highlights the rows of the current range', () => {
      expect(highlightedNewLines()).toEqual([6, 7]);
    });

    it('places the start handle on the start row and the end handle on the end row', () => {
      expect(findHandle('start').closest('tr')).toBe(getRows()[1]);
      expect(findHandle('end').closest('tr')).toBe(getRows()[2]);
    });

    it('moves focus to the end handle and describes the controls with the editing instructions', () => {
      expect(document.activeElement).toBe(findHandle('end'));

      const describedById = findHandle('end').getAttribute('aria-describedby');
      const instructions = document.getElementById(describedById);
      expect(instructions).not.toBeNull();
      expect(instructions.textContent).toContain('arrow keys');
      expect(findHandle('start').getAttribute('aria-describedby')).toBe(describedById);
      expect(findCancelButton().getAttribute('aria-describedby')).toBe(describedById);
    });
  });

  describe('dragging handles', () => {
    it('extends the range when the end handle is dragged down', async () => {
      await startEditing(6, 7);
      dragHandleToRow('end', getRows()[3]);
      expect(highlightedNewLines()).toEqual([6, 7, 8]);
    });

    it('extends the range when the start handle is dragged up', async () => {
      await startEditing(6, 7);
      dragHandleToRow('start', getRows()[0]);
      expect(highlightedNewLines()).toEqual([5, 6, 7]);
    });
  });

  describe('keyboard support', () => {
    it('moves the end boundary down with ArrowDown', async () => {
      await startEditing(6, 7);
      findHandle('end').dispatchEvent(
        new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true }),
      );
      expect(highlightedNewLines()).toEqual([6, 7, 8]);
    });

    it('moves the start boundary up with ArrowUp', async () => {
      await startEditing(6, 7);
      findHandle('start').dispatchEvent(
        new KeyboardEvent('keydown', { key: 'ArrowUp', bubbles: true }),
      );
      expect(highlightedNewLines()).toEqual([5, 6, 7]);
    });

    it('moves focus to the start handle with ArrowLeft', async () => {
      await startEditing(6, 7);
      findHandle('end').focus();
      findHandle('end').dispatchEvent(
        new KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true }),
      );
      expect(document.activeElement).toBe(findHandle('start'));
    });

    it('moves focus to the end handle with ArrowRight', async () => {
      await startEditing(6, 7);
      findHandle('start').focus();
      findHandle('start').dispatchEvent(
        new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }),
      );
      expect(document.activeElement).toBe(findHandle('end'));
    });

    describe('with a single-line range', () => {
      it('shifts the range down when ArrowDown is pressed on the start handle', async () => {
        await startEditing(6, 6);
        findHandle('start').dispatchEvent(
          new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true }),
        );
        expect(highlightedNewLines()).toEqual([7]);
      });

      it('shifts the range up when ArrowUp is pressed on the end handle', async () => {
        await startEditing(6, 6);
        findHandle('end').dispatchEvent(
          new KeyboardEvent('keydown', { key: 'ArrowUp', bubbles: true }),
        );
        expect(highlightedNewLines()).toEqual([5]);
      });

      it('expands upward when ArrowUp is pressed on the start handle', async () => {
        await startEditing(6, 6);
        findHandle('start').dispatchEvent(
          new KeyboardEvent('keydown', { key: 'ArrowUp', bubbles: true }),
        );
        expect(highlightedNewLines()).toEqual([5, 6]);
      });

      it('expands downward when ArrowDown is pressed on the end handle', async () => {
        await startEditing(6, 6);
        findHandle('end').dispatchEvent(
          new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true }),
        );
        expect(highlightedNewLines()).toEqual([6, 7]);
      });
    });
  });

  describe('committing', () => {
    it('commits the edited range when a handle drag ends', async () => {
      await startEditing(6, 7);
      dragHandleToRow('end', getRows()[3]);

      expect(store.lineRangeEditing.lineRange).toStrictEqual({
        start: newSidePos(6),
        end: newSidePos(8),
      });
      expect(store.commitLineRangeEditing).toHaveBeenCalledWith({
        lineChange: { change: 'added', position: 'old' },
        lineCode: 'abc_0_8',
        lines: ['line 6', 'line 7', 'line 8'],
      });
    });

    it('commits when Enter is pressed on a handle', async () => {
      await startEditing(6, 7);
      findHandle('end').dispatchEvent(
        new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }),
      );

      expect(store.commitLineRangeEditing).toHaveBeenCalled();
    });
  });

  describe('parallel view', () => {
    beforeEach(() => {
      resetHTMLFixture();
      createTestingPinia({ stubActions: false });
      mount(parallelFixture, 'text_parallel');
    });

    it('commits the same lineChange position and content as the inline path', async () => {
      await startEditing(6, 7);
      dragHandleToRow('end', getRows()[3]);

      expect(store.lineRangeEditing.lineRange).toStrictEqual({
        start: newSidePos(6),
        end: newSidePos(8),
      });
      expect(store.commitLineRangeEditing).toHaveBeenCalledWith({
        lineChange: { change: 'added', position: 'new' },
        lineCode: 'abc_0_8',
        lines: ['line 6', 'line 7', 'line 8'],
      });
    });
  });

  describe('cancelling', () => {
    it('cancels editing when Escape is pressed', async () => {
      await startEditing(6, 7);
      appElement.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
      expect(store.cancelLineRangeEditing).toHaveBeenCalled();
    });

    it('cancels editing when the cancel button is clicked', async () => {
      await startEditing(6, 7);
      findCancelButton().dispatchEvent(new MouseEvent('click', { bubbles: true }));
      expect(store.cancelLineRangeEditing).toHaveBeenCalled();
    });
  });

  describe('when editing stops', () => {
    it('removes the controls and clears the highlight', async () => {
      await startEditing(6, 7);
      store.setEditing(null);
      await waitForPromises();

      expect(findHandles()).toHaveLength(0);
      expect(findCancelButton()).toBeNull();
      expect(highlightedNewLines()).toEqual([]);
      expect(getDiffFile().dataset.lineRangeEditing).toBeUndefined();
    });
  });

  describe('when editing starts again for a different range', () => {
    it('replaces the previous controls instead of duplicating them', async () => {
      await startEditing(6, 7);
      await startEditing(5, 8);

      expect(findHandles()).toHaveLength(2);
      expect(appElement.querySelectorAll('[data-line-range-cancel]')).toHaveLength(1);
      expect(document.querySelectorAll('#rd-line-range-editing-instructions')).toHaveLength(1);
    });
  });

  describe('when the diff file cannot be found', () => {
    it('cancels editing', async () => {
      store.setEditing({
        ...editingContext(6, 7),
        discussion: { position: { old_path: 'missing.js', new_path: 'missing.js' } },
      });
      await waitForPromises();
      expect(store.cancelLineRangeEditing).toHaveBeenCalled();
    });
  });
});
