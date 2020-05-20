import $ from 'jquery';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import Autosave from '~/autosave';
import AccessorUtilities from '~/lib/utils/accessor';

describe('Autosave', () => {
  useLocalStorageSpy();

  let autosave;
  const field = $('<textarea></textarea>');
  const key = 'key';
  const fallbackKey = 'fallbackKey';
  const lockVersionKey = 'lockVersionKey';
  const lockVersion = 1;

  describe('class constructor', () => {
    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').mockReturnValue(true);
      jest.spyOn(Autosave.prototype, 'restore').mockImplementation(() => {});
    });

    it('should set .isLocalStorageAvailable', () => {
      autosave = new Autosave(field, key);

      expect(AccessorUtilities.isLocalStorageAccessSafe).toHaveBeenCalled();
      expect(autosave.isLocalStorageAvailable).toBe(true);
    });

    it('should set .isLocalStorageAvailable if fallbackKey is passed', () => {
      autosave = new Autosave(field, key, fallbackKey);

      expect(AccessorUtilities.isLocalStorageAccessSafe).toHaveBeenCalled();
      expect(autosave.isLocalStorageAvailable).toBe(true);
    });

    it('should set .isLocalStorageAvailable if lockVersion is passed', () => {
      autosave = new Autosave(field, key, null, lockVersion);

      expect(AccessorUtilities.isLocalStorageAccessSafe).toHaveBeenCalled();
      expect(autosave.isLocalStorageAvailable).toBe(true);
    });
  });

  describe('restore', () => {
    beforeEach(() => {
      autosave = {
        field,
        key,
      };
    });

    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = false;

        Autosave.prototype.restore.call(autosave);
      });

      it('should not call .getItem', () => {
        expect(window.localStorage.getItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = true;
      });

      it('should call .getItem', () => {
        Autosave.prototype.restore.call(autosave);

        expect(window.localStorage.getItem).toHaveBeenCalledWith(key);
      });

      it('triggers jquery event', () => {
        jest.spyOn(autosave.field, 'trigger').mockImplementation(() => {});

        Autosave.prototype.restore.call(autosave);

        expect(field.trigger).toHaveBeenCalled();
      });

      it('triggers native event', () => {
        const fieldElement = autosave.field.get(0);
        const eventHandler = jest.fn();
        fieldElement.addEventListener('change', eventHandler);

        Autosave.prototype.restore.call(autosave);

        expect(eventHandler).toHaveBeenCalledTimes(1);
        fieldElement.removeEventListener('change', eventHandler);
      });
    });

    describe('if field gets deleted from DOM', () => {
      beforeEach(() => {
        autosave.field = $('.not-a-real-element');
      });

      it('does not trigger event', () => {
        jest.spyOn(field, 'trigger');

        expect(field.trigger).not.toHaveBeenCalled();
      });
    });
  });

  describe('getSavedLockVersion', () => {
    beforeEach(() => {
      autosave = {
        field,
        key,
        lockVersionKey,
      };
    });

    describe('if .isLocalStorageAvailable is `false`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = false;

        Autosave.prototype.getSavedLockVersion.call(autosave);
      });

      it('should not call .getItem', () => {
        expect(window.localStorage.getItem).not.toHaveBeenCalled();
      });
    });

    describe('if .isLocalStorageAvailable is `true`', () => {
      beforeEach(() => {
        autosave.isLocalStorageAvailable = true;
      });

      it('should call .getItem', () => {
        Autosave.prototype.getSavedLockVersion.call(autosave);

        expect(window.localStorage.getItem).toHaveBeenCalledWith(lockVersionKey);
      });
    });
  });

  describe('save', () => {
    beforeEach(() => {
      autosave = { reset: jest.fn() };
      autosave.field = field;
      field.val('value');
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
