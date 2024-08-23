import Counter from '~/glql/utils/counter';

describe('Counter', () => {
  let counter;

  beforeEach(() => {
    counter = new Counter();
  });

  describe('constructor', () => {
    it('initializes with default values', () => {
      expect(counter.value).toBe(0);
      expect(counter.max).toBe(20);
    });

    it('initializes with custom max value', () => {
      const customCounter = new Counter(30);
      expect(customCounter.value).toBe(0);
      expect(customCounter.max).toBe(30);
    });
  });

  describe('increment', () => {
    it('increments the counter', () => {
      expect(counter.increment()).toBe(1);
      expect(counter.value).toBe(1);
    });

    it('throws an error when exceeding max value', () => {
      for (let i = 0; i < 20; i += 1) {
        counter.increment();
      }
      expect(() => counter.increment()).toThrow('Counter exceeded max value');
    });
  });

  describe('reset', () => {
    it('resets the counter to 0', () => {
      counter.increment();
      counter.increment();
      counter.reset();
      expect(counter.value).toBe(0);
    });
  });

  describe('value getter', () => {
    it('returns the current value', () => {
      expect(counter.value).toBe(0);
      counter.increment();
      expect(counter.value).toBe(1);
    });
  });

  describe('max property', () => {
    it('allows changing the max value', () => {
      counter.max = 5;
      for (let i = 0; i < 5; i += 1) {
        counter.increment();
      }
      expect(() => counter.increment()).toThrow('Counter exceeded max value');
    });
  });
});
