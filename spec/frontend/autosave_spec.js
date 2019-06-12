import $ from 'jquery';
import Autosave from '~/autosave';
import AccessorUtilities from '~/lib/utils/accessor';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

describe('Autosave', () => {
  useLocalStorageSpy();

  let autosave;
  const field = $('<textarea></textarea>');
  const key = 'key';

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

      it('triggers native event', done => {
        autosave.field.get(0).addEventListener('change', () => {
          done();
        });

        Autosave.prototype.restore.call(autosave);
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

  describe('reset', () => {
    beforeEach(() => {
      autosave = {
        key,
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
      });
    });
  });
});
