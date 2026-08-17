import Sortable from 'sortablejs';
import { installRevertOnEscapePlugin } from '~/sortable/plugins/revert_on_escape';

// The mock in spec/frontend/__mocks__/sortablejs stubs out real drag behaviour,
// but this plugin needs the real Sortable.js plugin lifecycle to be exercised.
jest.unmock('sortablejs');

describe('RevertOnEscape', () => {
  let list;
  let sortable;

  const plugin = () => sortable.revertOnEscape;

  const dispatchEscape = () => {
    document.dispatchEvent(new KeyboardEvent('keyup', { key: 'Escape' }));
  };

  beforeEach(() => {
    installRevertOnEscapePlugin();

    list = document.createElement('ul');
    list.innerHTML = '<li>a</li><li>b</li><li>c</li>';
    document.body.appendChild(list);

    sortable = Sortable.create(list, {
      forceFallback: true,
      revertOnEscape: true,
    });
  });

  afterEach(() => {
    sortable.destroy();
    list.remove();
  });

  it('installs itself on the Sortable instance when the revertOnEscape option is set', () => {
    expect(plugin()).toBeDefined();
  });

  it('does not install itself when the revertOnEscape option is not set', () => {
    const plainList = document.createElement('ul');
    plainList.innerHTML = '<li>a</li><li>b</li>';
    document.body.appendChild(plainList);

    const plainSortable = Sortable.create(plainList, { forceFallback: true });

    expect(plainSortable.revertOnEscape).toBeUndefined();

    plainSortable.destroy();
    plainList.remove();
  });

  it('mounts the underlying Sortable.js plugin only once, even if called again', () => {
    const mountSpy = jest.spyOn(Sortable, 'mount');

    installRevertOnEscapePlugin();
    installRevertOnEscapePlugin();

    expect(mountSpy).not.toHaveBeenCalled();
  });

  describe('dragStart', () => {
    it('records the starting index and resets escapePressed', () => {
      plugin().escapePressed = true;

      plugin().dragStart({ oldDraggableIndex: 1 });

      expect(plugin().escapePressed).toBe(false);
      expect(plugin().startIndex).toBe(1);
    });
  });

  describe('dragOver', () => {
    it('ignores events for a different active sortable', () => {
      const cancel = jest.fn();

      plugin().dragOver({
        activeSortable: {},
        cancel,
        dragEl: list.children[0],
        ghostEl: document.createElement('li'),
      });

      expect(cancel).not.toHaveBeenCalled();
      expect(plugin().keyUpHandler).toBeNull();
    });

    it('registers a single keyup listener while dragging is in progress', () => {
      const addEventListenerSpy = jest.spyOn(document, 'addEventListener');
      const dragEl = list.children[0];
      const ghostEl = document.createElement('li');

      plugin().dragOver({ activeSortable: sortable, cancel: jest.fn(), dragEl, ghostEl });
      plugin().dragOver({ activeSortable: sortable, cancel: jest.fn(), dragEl, ghostEl });

      expect(addEventListenerSpy).toHaveBeenCalledTimes(1);
      expect(addEventListenerSpy).toHaveBeenCalledWith('keyup', expect.any(Function));
    });

    it('cancels the drag on the next dragOver once Escape has been pressed', () => {
      const dragEl = list.children[0];
      const ghostEl = document.createElement('li');
      const cancel = jest.fn();

      plugin().dragOver({ activeSortable: sortable, cancel, dragEl, ghostEl });
      plugin().escapePressed = true;
      plugin().dragOver({ activeSortable: sortable, cancel, dragEl, ghostEl });

      expect(cancel).toHaveBeenCalled();
    });

    it('restores the dragged element to its starting position when Escape is pressed', () => {
      const dragEl = list.children[1];
      const ghostEl = document.createElement('li');

      plugin().dragStart({ oldDraggableIndex: 1 });
      plugin().dragOver({ activeSortable: sortable, cancel: jest.fn(), dragEl, ghostEl });

      // Simulate the drag having moved dragEl to the end of the list.
      list.appendChild(dragEl);

      dispatchEscape();

      expect(plugin().escapePressed).toBe(true);
      expect(Array.from(list.children).indexOf(dragEl)).toBe(1);
      expect(dragEl.classList.contains(plugin().options.ghostClass)).toBe(false);
      expect(ghostEl.style.display).toBe('none');
    });

    it('removes the keyup listener once Escape has restored the drag', () => {
      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener');
      const dragEl = list.children[0];
      const ghostEl = document.createElement('li');

      plugin().dragOver({ activeSortable: sortable, cancel: jest.fn(), dragEl, ghostEl });
      dispatchEscape();

      expect(removeEventListenerSpy).toHaveBeenCalledWith('keyup', expect.any(Function));
      expect(plugin().keyUpHandler).toBeNull();
    });

    it('ignores key presses other than Escape', () => {
      const dragEl = list.children[0];
      const ghostEl = document.createElement('li');

      plugin().dragOver({ activeSortable: sortable, cancel: jest.fn(), dragEl, ghostEl });
      document.dispatchEvent(new KeyboardEvent('keyup', { key: 'Enter' }));

      expect(plugin().escapePressed).toBe(false);
      expect(plugin().keyUpHandler).not.toBeNull();
    });
  });

  describe('drop', () => {
    it('removes the keyup listener', () => {
      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener');
      const dragEl = list.children[0];
      const ghostEl = document.createElement('li');

      plugin().dragOver({ activeSortable: sortable, cancel: jest.fn(), dragEl, ghostEl });
      plugin().drop();

      expect(removeEventListenerSpy).toHaveBeenCalledWith('keyup', expect.any(Function));
      expect(plugin().keyUpHandler).toBeNull();
    });
  });

  describe('destroy', () => {
    it('removes the keyup listener', () => {
      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener');
      const dragEl = list.children[0];
      const ghostEl = document.createElement('li');

      plugin().dragOver({ activeSortable: sortable, cancel: jest.fn(), dragEl, ghostEl });
      plugin().destroy();

      expect(removeEventListenerSpy).toHaveBeenCalledWith('keyup', expect.any(Function));
      expect(plugin().keyUpHandler).toBeNull();
    });
  });
});
