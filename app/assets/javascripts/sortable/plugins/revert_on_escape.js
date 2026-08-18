import Sortable from 'sortablejs';
import { ESC_KEY } from '~/lib/utils/keys';

function createRevertOnEscapePlugin() {
  /**
   * Sortable.js plugin for allowing drag operations to be cancelled by pressing <kbd>Esc</kbd>.
   *
   * This plugin makes a few assumptions:
   *
   * - the sortable's `forceFallback` options is set to `true`
   * - the sortable doesn't interact with other sortables; see
   *   https://github.com/SortableJS/Sortable/blob/1.10.2/README.md#group-option
   * - the `revertOnSpill` plugin is not enabled (how they interact is untested)
   * - the `multiDrag` plugin is not enabled (how they interact is untested)
   */
  class RevertOnEscape {
    escapePressed = false;

    keyUpHandler = null;

    startIndex = null;

    constructor(sortable, el, options) {
      if (process.env.NODE_ENV !== 'production') {
        const { forceFallback, revertOnSpill, multiDrag, group } = options;

        if (!forceFallback) {
          // eslint-disable-next-line no-console
          console.warn('RevertOnEscape requires forceFallback to be true; got', forceFallback);
        }

        if (revertOnSpill) {
          // eslint-disable-next-line no-console
          console.warn(
            'RevertOnEscape requires revertOnSpill not to be enabled; got',
            revertOnSpill,
          );
        }

        if (multiDrag) {
          // eslint-disable-next-line no-console
          console.warn('RevertOnEscape requires multiDrag not to be enabled; got', multiDrag);
        }

        if (group != null) {
          // eslint-disable-next-line no-console
          console.warn(`RevertOnEscape requires group to be undefined or null; got`, group);
        }
      }
    }

    dragStart({ oldDraggableIndex }) {
      this.startIndex = oldDraggableIndex;
      this.escapePressed = false;
    }

    dragOver({ activeSortable, cancel, dragEl, ghostEl, cloneEl }) {
      if (activeSortable !== this.sortable) return;
      if (this.escapePressed) cancel();
      if (this.keyUpHandler) return;

      this.keyUpHandler = (keyUpEvent) => {
        if (keyUpEvent.key !== ESC_KEY) return;

        this.escapePressed = true;
        this.removeKeyUpHandler();
        this.restore({ dragEl, ghostEl, cloneEl });
      };

      document.addEventListener('keyup', this.keyUpHandler);
    }

    restore({ dragEl, ghostEl }) {
      // Confusingly, dragEl is the element that gets ghostClass applied,
      // and is shifted around the list as the user drags, but is the real,
      // original element that the user wanted to move.
      dragEl.classList.remove(this.options.ghostClass);

      // Also confusingly, ghostEl is the copy of dragEl that follows under the
      // user's cursor. There is a hideGhostForTarget method available, but for
      // unclear reasons, it is a noop on browsers which support pointer
      // events. See:
      // https://github.com/SortableJS/Sortable/blob/1.10.2/src/Sortable.js#L288
      // eslint-disable-next-line no-param-reassign
      ghostEl.style.display = 'none';

      this.sortable.captureAnimationState();

      const nextSibling = Sortable.utils.getChild(this.sortable.el, this.startIndex, this.options);

      if (nextSibling) {
        this.sortable.el.insertBefore(dragEl, nextSibling);
      } else {
        this.sortable.el.appendChild(dragEl);
      }
      this.sortable.animateAll();
    }

    removeKeyUpHandler() {
      if (!this.keyUpHandler) return;

      document.removeEventListener('keyup', this.keyUpHandler);
      this.keyUpHandler = null;
    }

    drop() {
      this.removeKeyUpHandler();
    }

    destroy() {
      this.removeKeyUpHandler();
    }
  }

  return Object.assign(RevertOnEscape, {
    pluginName: 'revertOnEscape',
    initializeByDefault: false,
  });
}

let installed = false;

/**
 * Install the Sortable.js plugin.
 *
 * This ensures it's only installed once. Sortable.js doesn't provide a way to
 * prevent duplicate installs.
 */
export function installRevertOnEscapePlugin() {
  if (installed) return;

  Sortable.mount(createRevertOnEscapePlugin());
  installed = true;
}
