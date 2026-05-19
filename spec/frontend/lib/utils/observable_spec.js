import { observable, resetObservable } from '~/lib/utils/observable';

describe('observable', () => {
  afterEach(() => {
    resetObservable('test1');
    resetObservable('test2');
    resetObservable('test3');
    resetObservable('test4');
    resetObservable('test5');
    resetObservable('test6');
    resetObservable('test-a');
    resetObservable('test-b');
    resetObservable('test-multi');
  });

  it('supports basic read and write', () => {
    const state = observable('test1', { count: 0 });

    expect(state.count).toBe(0);

    state.count = 5;

    expect(state.count).toBe(5);
  });

  it('shares state across calls with the same key', () => {
    const first = observable('test2', { val: 'a' });
    const second = observable('test2', { val: 'b' });

    expect(first.val).toBe('a');
    expect(second.val).toBe('a');

    first.val = 'changed';

    expect(second.val).toBe('changed');

    second.val = 'again';

    expect(first.val).toBe('again');
  });

  it('applies defaults only on the first call', () => {
    const first = observable('test3', { x: 1 });
    const second = observable('test3', { x: 999 });

    expect(first.x).toBe(1);
    expect(second.x).toBe(1);
  });

  it('preserves getter properties', () => {
    const state = observable('test4', {
      a: 1,
      b: 2,
      get sum() {
        return this.a + this.b;
      },
    });

    expect(state.sum).toBe(3);

    state.a = 10;

    expect(state.sum).toBe(12);
  });

  it('preserves methods with correct this binding', () => {
    const state = observable('test5', {
      name: '',
      updateName(value) {
        this.name = value;
      },
    });

    state.updateName('hello');

    expect(state.name).toBe('hello');
  });

  it('works with a pre-populated object', () => {
    const existing = { color: 'red', size: 42 };
    const state = observable('test6', existing);

    expect(state.color).toBe('red');
    expect(state.size).toBe(42);

    state.color = 'blue';

    expect(state.color).toBe('blue');
    expect(existing.color).toBe('red');
  });

  it('supports property enumeration', () => {
    const state = observable('test1', { a: 1, b: 2, c: 3 });

    expect(Object.keys(state)).toEqual(['a', 'b', 'c']);
  });

  it('supports the in operator', () => {
    const state = observable('test1', { present: true });

    expect('present' in state).toBe(true);
    expect('absent' in state).toBe(false);
  });

  it('syncs across multiple mirrors', () => {
    const m1 = observable('test-multi', { n: 0 });
    const m2 = observable('test-multi', { n: 0 });
    const m3 = observable('test-multi', { n: 0 });

    m1.n = 42;

    expect(m2.n).toBe(42);
    expect(m3.n).toBe(42);

    m3.n = 99;

    expect(m1.n).toBe(99);
    expect(m2.n).toBe(99);
  });

  it('keeps independent keys isolated', () => {
    const a = observable('test-a', { x: 1 });
    const b = observable('test-b', { x: 2 });

    a.x = 100;

    expect(b.x).toBe(2);
  });

  describe('resetObservable', () => {
    it('clears state so next call creates fresh defaults', () => {
      const first = observable('test1', { val: 'original' });
      first.val = 'modified';

      resetObservable('test1');

      const second = observable('test1', { val: 'fresh' });

      expect(second.val).toBe('fresh');
    });
  });

  it('works with Object.assign', () => {
    const state = observable('test1', { a: 1, b: 2 });

    Object.assign(state, { a: 10, b: 20 });

    expect(state.a).toBe(10);
    expect(state.b).toBe(20);
  });
});
