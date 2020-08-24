import { createFakeDateClass, DEFAULT_ARGS, useRealDate } from './fake_date';

describe('spec/helpers/fake_date', () => {
  describe('createFakeDateClass', () => {
    let FakeDate;

    beforeAll(() => {
      useRealDate();
    });

    beforeEach(() => {
      FakeDate = createFakeDateClass(DEFAULT_ARGS);
    });

    it('should use default args', () => {
      expect(new FakeDate()).toEqual(new Date(...DEFAULT_ARGS));
      expect(FakeDate()).toEqual(Date(...DEFAULT_ARGS));
    });

    it('should have deterministic now()', () => {
      expect(FakeDate.now()).not.toBe(Date.now());
      expect(FakeDate.now()).toBe(new Date(...DEFAULT_ARGS).getTime());
    });

    it('should be instanceof Date', () => {
      expect(new FakeDate()).toBeInstanceOf(Date);
    });

    it('should be instanceof self', () => {
      expect(new FakeDate()).toBeInstanceOf(FakeDate);
    });
  });
});
