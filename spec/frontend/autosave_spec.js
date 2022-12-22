import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import Autosave from '~/autosave';
import AccessorUtilities from '~/lib/utils/accessor';

describe('Autosave', () => {
  useLocalStorageSpy();

  let autosave;
  const field = document.createElement('textarea');
  const checkbox = document.createElement('input');
  checkbox.type = 'checkbox';
  const key = 'key';
  const fallbackKey = 'fallbackKey';
  const lockVersionKey = 'lockVersionKey';
  const lockVersion = 1;
  const getAutosaveKey = () => `autosave/${key}`;
  const getAutosaveLockKey = () => `autosave/${key}/lockVersion`;

  afterEach(() => {
    autosave?.dispose?.();
  });

  describe('class constructor', () => {
    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(true);
      jest.spyOn(Autosave.prototype, 'restore').mockImplementation(() => {});
    });

    it('should set .isLocalStorageAvailable', () => {
      autosave = new Autosave(field, key);

      expect(AccessorUtilities.canUseLocalStorage).toHaveBeenCalled();
      expect(autosave.isLocalStorageAvailable).toBe(true);
    });

    it('should set .isLocalStorageAvailable if fallbackKey is passed', () => {
      autosave = new Autosave(field, key, fallbackKey);

      expect(AccessorUtilities.canUseLocalStorage).toHaveBeenCalled();
      expect(autosave.isLocalStorageAvailable).toBe(true);
    });

    it('should set .isLocalStorageAvailable if lockVersion is passed', () => {
      autosave = new Autosave(field, key, null, lockVersion);

      expect(AccessorUtilities.canUseLocalStorage).toHaveBeenCalled();
      expect(autosave.isLocalStorageAvailable).toBe(true);
    });
  });

  describe('restore', () => {
    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);
        autosave = new Autosave(field, key);
      });

      it('should not call .getItem', () => {
        expect(window.localStorage.getItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      it('should call .getItem', () => {
        autosave = new Autosave(field, key);
        expect(window.localStorage.getItem.mock.calls).toEqual([[getAutosaveKey()], []]);
      });

      describe('if saved value is present', () => {
        const storedValue = 'bar';

        beforeEach(() => {
          field.value = 'foo';
          window.localStorage.setItem(getAutosaveKey(), storedValue);
        });

        it('restores the value', () => {
          autosave = new Autosave(field, key);
          expect(field.value).toEqual(storedValue);
        });

        it('triggers native event', () => {
          const eventHandler = jest.fn();
          field.addEventListener('change', eventHandler);
          autosave = new Autosave(field, key);

          expect(eventHandler).toHaveBeenCalledTimes(1);
          field.removeEventListener('change', eventHandler);
        });

        describe('if field type is checkbox', () => {
          beforeEach(() => {
            checkbox.checked = false;
            window.localStorage.setItem(getAutosaveKey(), true);
            autosave = new Autosave(checkbox, key);
          });

          it('should restore', () => {
            expect(checkbox.checked).toBe(true);
          });
        });
      });
    });
  });

  describe('getSavedLockVersion', () => {
    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);
        autosave = new Autosave(field, key);
      });

      it('should not call .getItem', () => {
        autosave.getSavedLockVersion();
        expect(window.localStorage.getItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        autosave = new Autosave(field, key);
      });

      it('should call .getItem', () => {
        autosave.getSavedLockVersion();
        expect(window.localStorage.getItem.mock.calls).toEqual([
          [getAutosaveKey()],
          [],
          [getAutosaveLockKey()],
        ]);
      });
    });
  });

  describe('save', () => {
    beforeEach(() => {
      autosave = { reset: jest.fn() };
      autosave.field = field;
      field.value = 'value';
    });

    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = false;

        Autosave.prototype.save.call(autosave);
      });

      it('should not call .setItem', () => {
        expect(window.localStorage.setItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = true;

        Autosave.prototype.save.call(autosave);
      });

      it('should call .setItem', () => {
        expect(window.localStorage.setItem).toHaveBeenCalled();
      });
    });

    describe('if field type is checkbox', () => {
      beforeEach(() => {
        autosave = {
          field: checkbox,
          key,
          isLocalStorageAvailable: true,
          type: 'checkbox',
        };
      });

      it('should save true when checkbox on', () => {
        checkbox.checked = true;
        Autosave.prototype.save.call(autosave);
        expect(window.localStorage.setItem).toHaveBeenCalledWith(key, true);
      });

      it('should call reset when checkbox off', () => {
        autosave.reset = jest.fn();
        checkbox.checked = false;
        Autosave.prototype.save.call(autosave);
        expect(autosave.reset).toHaveBeenCalled();
        expect(window.localStorage.setItem).not.toHaveBeenCalled();
      });
    });
  });

  describe('save with lockVersion', () => {
    beforeEach(() => {
      autosave = {
        field,
        key,
        lockVersionKey,
        lockVersion,
        isLocalStorageAvailable: true,
      };
    });

    describe('lockVersion is valid', () => {
      it('should call .setItem', () => {
        Autosave.prototype.save.call(autosave);
        expect(window.localStorage.setItem).toHaveBeenCalledWith(lockVersionKey, lockVersion);
      });

      it('should call .setItem when version is 0', () => {
        autosave.lockVersion = 0;
        Autosave.prototype.save.call(autosave);
        expect(window.localStorage.setItem).toHaveBeenCalledWith(
          lockVersionKey,
          autosave.lockVersion,
        );
      });
    });

    describe('lockVersion is invalid', () => {
      it('should not call .setItem with lockVersion', () => {
        delete autosave.lockVersion;
        Autosave.prototype.save.call(autosave);

        expect(window.localStorage.setItem).not.toHaveBeenCalledWith(
          lockVersionKey,
          autosave.lockVersion,
        );
      });
    });
  });

  describe('reset', () => {
    beforeEach(() => {
      autosave = {
        key,
        lockVersionKey,
      };
    });

    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = false;

        Autosave.prototype.reset.call(autosave);
      });

      it('should not call .removeItem', () => {
        expect(window.localStorage.removeItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = true;

        Autosave.prototype.reset.call(autosave);
      });

      it('should call .removeItem', () => {
        expect(window.localStorage.removeItem).toHaveBeenCalledWith(key);
        expect(window.localStorage.removeItem).toHaveBeenCalledWith(lockVersionKey);
      });
    });
  });

  describe('restore with fallbackKey', () => {
    beforeEach(() => {
      autosave = {
        field,
        key,
        fallbackKey,
        isLocalStorageAvailable: true,
      };
    });

    it('should call .getItem', () => {
      Autosave.prototype.restore.call(autosave);

      expect(window.localStorage.getItem).toHaveBeenCalledWith(fallbackKey);
    });

    it('should call .setItem for key and fallbackKey', () => {
      Autosave.prototype.save.call(autosave);

      expect(window.localStorage.setItem).toHaveBeenCalledTimes(2);
    });

    it('should call .removeItem for key and fallbackKey', () => {
      Autosave.prototype.reset.call(autosave);

      expect(window.localStorage.removeItem).toHaveBeenCalledWith(fallbackKey);
      expect(window.localStorage.removeItem).toHaveBeenCalledWith(key);
    });
  });
});
