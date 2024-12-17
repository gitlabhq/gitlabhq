import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import getUnicodeSupportMap from '~/emoji/support/unicode_support_map';
import AccessorUtilities from '~/lib/utils/accessor';

describe('Unicode Support Map', () => {
  useLocalStorageSpy();
  describe('getUnicodeSupportMap', () => {
    const stringSupportMap = 'stringSupportMap';

    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockImplementation(() => {});
      jest.spyOn(JSON, 'parse').mockImplementation(() => {});
      jest.spyOn(JSON, 'stringify').mockReturnValue(stringSupportMap);
    });

    describe('if isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);

        getUnicodeSupportMap();
      });

      it('should call .getItem and .setItem', () => {
        const getArgs = window.localStorage.getItem.mock.calls;
        const setArgs = window.localStorage.setItem.mock.calls;

        expect(getArgs[0][0]).toBe('gl-emoji-version');
        expect(getArgs[1][0]).toBe('gl-emoji-user-agent');

        expect(setArgs[0][0]).toBe('gl-emoji-version');
        expect(setArgs[0][1]).toBe('0.3.0');
        expect(setArgs[1][0]).toBe('gl-emoji-user-agent');
        expect(setArgs[1][1]).toBe(navigator.userAgent);
        expect(setArgs[2][0]).toBe('gl-emoji-unicode-support-map');
        expect(setArgs[2][1]).toBe(stringSupportMap);
      });
    });

    describe('if isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);

        getUnicodeSupportMap();
      });

      it('should not call .getItem or .setItem', () => {
        expect(window.localStorage.getItem.mock.calls.length).toBe(1);
        expect(window.localStorage.setItem).not.toHaveBeenCalled();
      });
    });
  });
});
