import { createFakeDateClass } from './fake_date';

describe('spec/helpers/fake_date', () => {
  describe('createFakeDateClass', () => {
    let FakeDate;

    beforeEach(() => {
      FakeDate = createFakeDateClass();
    });

    it('should use default args', () => {
      expect(new FakeDate()).toMatchInlineSnapshot(`2020-07-06T00:00:00.000Z`);
    });

    it('should use default args when called as a function', () => {
      expect(FakeDate()).toMatchInlineSnapshot(
        `"Mon Jul 06 2020 00:00:00 GMT+0000 (Greenwich Mean Time)"`,
      );
    });

    it('should have deterministic now()', () => {
      expect(FakeDate.now()).toMatchInlineSnapshot(`1593993600000`);
    });

    it('should be instanceof Date', () => {
      expect(new FakeDate()).toBeInstanceOf(Date);
    });

    it('should be instanceof self', () => {
      expect(new FakeDate()).toBeInstanceOf(FakeDate);
    });
  });
});
