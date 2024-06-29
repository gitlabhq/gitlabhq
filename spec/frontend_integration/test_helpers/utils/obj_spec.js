import { withKeys, withValues } from './obj';

describe('frontend_integration/test_helpers/utils/obj', () => {
  describe('withKeys', () => {
    it('picks and maps keys', () => {
      expect(withKeys({ a: '123', b: 456, c: 'd' }, { b: 'lorem', c: 'ipsum', z: 'zed ' })).toEqual(
        { lorem: 456, ipsum: 'd' },
      );
    });
  });

  describe('withValues', () => {
    it('sets values', () => {
      expect(withValues({ a: '123', b: 456 }, { b: 789 })).toEqual({ a: '123', b: 789 });
    });

    it('throws if values has non-existent key', () => {
      expect(() => withValues({ a: '123', b: 456 }, { b: 789, bogus: 'throws' })).toThrow(
        `[mock_server] Cannot write property that does not exist on object 'bogus'`,
      );
    });
  });
});
