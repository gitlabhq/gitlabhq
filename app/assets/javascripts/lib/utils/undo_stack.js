/**
 * UndoStack provides a custom implementation of an undo/redo engine. It was originally written for GitLab's Markdown editor (`gl_form.js`), whose rich text editing capabilities broke native browser undo/redo behaviour.
 *
 * UndoStack supports predictable undos/redos, debounced saves, maximum history length, and duplicate detection.
 *
 * Usage:
 *   - `stack = new UndoStack();`
 *   - Saves a state to the stack with `stack.save(state)`.
 *   - Get the current state with `stack.current()`.
 *   - Revert to the previous state with `stack.undo()`.
 *   - Redo a previous undo with `stack.redo()`;
 *   - Queue a future save with `stack.scheduleSave(state, delay)`. Useful for text editors.
 *   - See the full undo history in `stack.history`.
 */
export default class UndoStack {
  constructor(maxLength = 1000) {
    this.clear();
    this.maxLength = maxLength;

    // If you're storing reference-types in the undo stack, you might want to
    // reassign this property to some deep-equals function.
    this.comparator = (a, b) => a === b;
  }

  current() {
    if (this.cursor === -1) {
      return undefined;
    }
    return this.history[this.cursor];
  }

  isEmpty() {
    return this.history.length === 0;
  }

  clear() {
    this.clearPending();
    this.history = [];
    this.cursor = -1;
  }

  save(state) {
    this.clearPending();
    if (this.comparator(state, this.current())) {
      // Don't save state if it's the same as the current state
      return;
    }

    this.history.length = this.cursor + 1;
    this.history.push(state);
    this.cursor += 1;

    if (this.history.length > this.maxLength) {
      this.history.shift();
      this.cursor -= 1;
    }
  }

  scheduleSave(state, delay = 1000) {
    this.clearPending();
    this.pendingState = state;
    this.timeout = setTimeout(this.saveNow.bind(this), delay);
  }

  saveNow() {
    // Persists scheduled saves immediately
    this.save(this.pendingState);
    this.clearPending();
  }

  clearPending() {
    // Cancels any scheduled saves
    if (this.timeout) {
      clearTimeout(this.timeout);
      delete this.timeout;
      delete this.pendingState;
    }
  }

  canUndo() {
    return this.cursor > 0;
  }

  undo() {
    this.clearPending();
    if (!this.canUndo()) {
      return undefined;
    }
    this.cursor -= 1;
    return this.history[this.cursor];
  }

  canRedo() {
    return this.cursor >= 0 && this.cursor < this.history.length - 1;
  }

  redo() {
    this.clearPending();
    if (!this.canRedo()) {
      return undefined;
    }
    this.cursor += 1;
    return this.history[this.cursor];
  }
}
