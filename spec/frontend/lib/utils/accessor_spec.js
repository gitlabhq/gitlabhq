import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import AccessorUtilities from '~/lib/utils/accessor';

describe('AccessorUtilities', () => {
  useLocalStorageSpy();

  const testError = new Error('test error');

  describe('isPropertyAccessSafe', () => {
    let base;

    it('should return `true` if access is safe', () => {
      base = {
        testProp: 'testProp',
      };
      expect(AccessorUtilities.isPropertyAccessSafe(base, 'testProp')).toBe(true);
    });

    it('should return `false` if access throws an error', () => {
      base = {
        get testProp() {
          throw testError;
        },
      };

      expect(AccessorUtilities.isPropertyAccessSafe(base, 'testProp')).toBe(false);
    });

    it('should return `false` if property is undefined', () => {
      base = {};

      expect(AccessorUtilities.isPropertyAccessSafe(base, 'testProp')).toBe(false);
    });
  });

  describe('isFunctionCallSafe', () => {
    const base = {};

    it('should return `true` if calling is safe', () => {
      base.func = () => {};

      expect(AccessorUtilities.isFunctionCallSafe(base, 'func')).toBe(true);
    });

    it('should return `false` if calling throws an error', () => {
      base.func = () => {
        throw new Error('test error');
      };

      expect(AccessorUtilities.isFunctionCallSafe(base, 'func')).toBe(false);
    });

    it('should return `false` if function is undefined', () => {
      base.func = undefined;

      expect(AccessorUtilities.isFunctionCallSafe(base, 'func')).toBe(false);
    });
  });

  describe('isLocalStorageAccessSafe', () => {
    it('should return `true` if access is safe', () => {
      expect(AccessorUtilities.isLocalStorageAccessSafe()).toBe(true);
    });

    it('should return `false` if access to .setItem isnt safe', () => {
      window.localStorage.setItem.mockImplementation(() => {
        throw testError;
      });

      expect(AccessorUtilities.isLocalStorageAccessSafe()).toBe(false);
    });

    it('should set a test item if access is safe', () => {
      AccessorUtilities.isLocalStorageAccessSafe();

      expect(window.localStorage.setItem).toHaveBeenCalledWith('isLocalStorageAccessSafe', 'true');
    });

    it('should remove the test item if access is safe', () => {
      AccessorUtilities.isLocalStorageAccessSafe();

      expect(window.localStorage.removeItem).toHaveBeenCalledWith('isLocalStorageAccessSafe');
    });
  });
});
