const SHORTCUTS_MODULE_PATH = '~/behaviors/shortcuts/shortcuts';

// The shortcuts promise is created at module load, so each context needs a
// freshly isolated copy of the module.
const loadModule = () => {
  let mod;
  jest.isolateModules(() => {
    // eslint-disable-next-line global-require
    mod = require('~/behaviors/shortcuts');
  });
  return mod;
};

describe('~/behaviors/shortcuts', () => {
  describe('when the shortcuts bundle loads', () => {
    let addShortcutsExtension;

    beforeEach(() => {
      ({ addShortcutsExtension } = loadModule());
    });

    it('instantiates the extension with the shortcuts instance and args', async () => {
      const Extension = jest.fn();

      await addShortcutsExtension(Extension, 'foo', 'bar');

      expect(Extension).toHaveBeenCalledTimes(1);
      expect(Extension).toHaveBeenCalledWith(expect.anything(), 'foo', 'bar');
    });
  });

  describe('when the shortcuts bundle fails to load', () => {
    let addShortcutsExtension;

    beforeEach(() => {
      jest.doMock(SHORTCUTS_MODULE_PATH, () => {
        throw new Error('Failed to fetch dynamically imported module');
      });
      ({ addShortcutsExtension } = loadModule());
    });

    afterEach(() => {
      jest.dontMock(SHORTCUTS_MODULE_PATH);
    });

    it('resolves addShortcutsExtension without throwing', async () => {
      await expect(addShortcutsExtension(jest.fn())).resolves.toBeUndefined();
    });
  });
});
