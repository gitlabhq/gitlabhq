import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import AccessorUtilities from '~/lib/utils/accessor';

describe('AccessorUtilities', () => {
  useLocalStorageSpy();

  const testError = new Error('test error');

  describe('canUseLocalStorage', () => {
    it('should return `true` if access is safe', () => {
      expect(AccessorUtilities.canUseLocalStorage()).toBe(true);
    });

    it('should return `false` if access to .setItem isnt safe', () => {
      window.localStorage.setItem.mockImplementation(() => {
        throw testError;
      });

      expect(AccessorUtilities.canUseLocalStorage()).toBe(false);
    });

    it('should set a test item if access is safe', () => {
      AccessorUtilities.canUseLocalStorage();

      expect(window.localStorage.setItem).toHaveBeenCalledWith('canUseLocalStorage', 'true');
    });

    it('should remove the test item if access is safe', () => {
      AccessorUtilities.canUseLocalStorage();

      expect(window.localStorage.removeItem).toHaveBeenCalledWith('canUseLocalStorage');
    });
  });
});
