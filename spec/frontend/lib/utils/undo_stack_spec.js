import UndoStack from '~/lib/utils/undo_stack';

import { isEqual } from 'underscore';

describe('UndoStack', () => {
  let stack;

  beforeEach(() => {
    stack = new UndoStack();
  });

  afterEach(() => {
    // Make sure there's not pending saves
    const history = Array.from(stack.history);
    jest.runAllTimers();
    expect(stack.history).toEqual(history);
  });

  it('is blank on construction', () => {
    expect(stack.isEmpty()).toBe(true);
    expect(stack.history).toEqual([]);
    expect(stack.cursor).toBe(-1);
    expect(stack.canUndo()).toBe(false);
    expect(stack.canRedo()).toBe(false);
  });

  it('handles simple undo/redo behaviour', () => {
    stack.save(10);
    stack.save(11);
    stack.save(12);

    expect(stack.history).toEqual([10, 11, 12]);
    expect(stack.cursor).toBe(2);
    expect(stack.current()).toBe(12);
    expect(stack.isEmpty()).toBe(false);
    expect(stack.canUndo()).toBe(true);
    expect(stack.canRedo()).toBe(false);

    stack.undo();
    expect(stack.history).toEqual([10, 11, 12]);
    expect(stack.current()).toBe(11);
    expect(stack.canUndo()).toBe(true);
    expect(stack.canRedo()).toBe(true);

    stack.undo();
    expect(stack.current()).toBe(10);
    expect(stack.canUndo()).toBe(false);
    expect(stack.canRedo()).toBe(true);

    stack.redo();
    expect(stack.current()).toBe(11);

    stack.redo();
    expect(stack.current()).toBe(12);
    expect(stack.isEmpty()).toBe(false);
    expect(stack.canUndo()).toBe(true);
    expect(stack.canRedo()).toBe(false);

    // Saving should clear the redo stack
    stack.undo();
    stack.save(13);
    expect(stack.history).toEqual([10, 11, 13]);
    expect(stack.current()).toBe(13);
  });

  it('clear() should clear the undo history', () => {
    stack.save(0);
    stack.save(1);
    stack.save(2);
    stack.clear();
    expect(stack.history).toEqual([]);
    expect(stack.current()).toBeUndefined();
  });

  it('undo and redo are no-ops if unavailable', () => {
    stack.save(10);
    expect(stack.canRedo()).toBe(false);
    expect(stack.canUndo()).toBe(false);

    stack.save(11);
    expect(stack.canRedo()).toBe(false);
    expect(stack.canUndo()).toBe(true);

    expect(stack.redo()).toBeUndefined();
    expect(stack.history).toEqual([10, 11]);
    expect(stack.current()).toBe(11);
    expect(stack.canRedo()).toBe(false);
    expect(stack.canUndo()).toBe(true);

    expect(stack.undo()).toBe(10);
    expect(stack.undo()).toBeUndefined();
    expect(stack.history).toEqual([10, 11]);
    expect(stack.current()).toBe(10);
    expect(stack.canRedo()).toBe(true);
    expect(stack.canUndo()).toBe(false);
  });

  it('should not save a duplicate state', () => {
    stack.save(10);
    stack.save(11);
    stack.save(11);
    stack.save(10);
    stack.save(10);

    expect(stack.history).toEqual([10, 11, 10]);
  });

  it('uses the === operator to detect duplicates', () => {
    stack.save(10);
    stack.save(10);
    expect(stack.history).toEqual([10]);

    // eslint-disable-next-line eqeqeq
    expect(2 == '2' && '2' == 2).toBe(true);
    stack.clear();
    stack.save(2);
    stack.save(2);
    stack.save('2');
    stack.save('2');
    stack.save(2);
    expect(stack.history).toEqual([2, '2', 2]);

    const obj = {};
    stack.clear();
    stack.save(obj);
    stack.save(obj);
    stack.save({});
    stack.save({});
    expect(stack.history).toEqual([{}, {}, {}]);
  });

  it('should allow custom comparators', () => {
    stack.comparator = isEqual;
    const obj = {};
    stack.clear();
    stack.save(obj);
    stack.save(obj);
    stack.save({});
    stack.save({});
    expect(stack.history).toEqual([{}]);
  });

  it('should enforce a max number of undo states', () => {
    // Try 2000 saves. Only the last 1000 should be preserved.
    const sequence = Array(2000)
      .fill(0)
      .map((el, i) => i);
    sequence.forEach(stack.save.bind(stack));
    expect(stack.history.length).toBe(1000);
    expect(stack.history).toEqual(sequence.slice(1000));
    expect(stack.current()).toBe(1999);
    expect(stack.canUndo()).toBe(true);
    expect(stack.canRedo()).toBe(false);

    // Saving drops the oldest elements from the stack
    stack.save('end');
    expect(stack.history.length).toBe(1000);
    expect(stack.current()).toBe('end');
    expect(stack.history).toEqual([...sequence.slice(1001), 'end']);

    // If states were undone but the history is full, can still add.
    stack.undo();
    stack.undo();
    expect(stack.current()).toBe(1998);
    stack.save(3000);
    expect(stack.history.length).toBe(999);
    // should be [1001, 1002, ..., 1998, 3000]
    expect(stack.history).toEqual([...sequence.slice(1001, 1999), 3000]);

    // Try a different max length
    stack = new UndoStack(2);
    stack.save(0);
    expect(stack.history).toEqual([0]);
    stack.save(1);
    expect(stack.history).toEqual([0, 1]);
    stack.save(2);
    expect(stack.history).toEqual([1, 2]);
  });

  describe('scheduled saves', () => {
    it('should work', () => {
      // Schedules 1000 ms ahead by default
      stack.save(0);
      stack.scheduleSave(1);
      expect(stack.history).toEqual([0]);
      jest.advanceTimersByTime(999);
      expect(stack.history).toEqual([0]);
      jest.advanceTimersByTime(1);
      expect(stack.history).toEqual([0, 1]);
    });

    it('should have an adjustable delay', () => {
      stack.scheduleSave(2, 100);
      jest.advanceTimersByTime(100);
      expect(stack.history).toEqual([2]);
    });

    it('should cancel previous scheduled saves', () => {
      stack.scheduleSave(3);
      jest.advanceTimersByTime(100);
      stack.scheduleSave(4);
      jest.runAllTimers();
      expect(stack.history).toEqual([4]);
    });

    it('should be canceled by explicit saves', () => {
      stack.scheduleSave(5);
      stack.save(6);
      jest.runAllTimers();
      expect(stack.history).toEqual([6]);
    });

    it('should be canceled by undos and redos', () => {
      stack.save(1);
      stack.save(2);
      stack.scheduleSave(3);
      stack.undo();
      jest.runAllTimers();
      expect(stack.history).toEqual([1, 2]);
      expect(stack.current()).toBe(1);

      stack.scheduleSave(4);
      stack.redo();
      jest.runAllTimers();
      expect(stack.history).toEqual([1, 2]);
      expect(stack.current()).toBe(2);
    });

    it('should be persisted immediately with saveNow()', () => {
      stack.scheduleSave(7);
      stack.scheduleSave(8);
      stack.saveNow();
      jest.runAllTimers();
      expect(stack.history).toEqual([8]);
    });
  });
});
