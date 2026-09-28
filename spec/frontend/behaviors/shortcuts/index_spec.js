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
  beforeEach(() => {
    delete document.body.dataset.shortcutsReady;
  });

  describe('when the shortcuts bundle loads', () => {
    let addShortcutsExtension;
    let markShortcutExtensionReady;

    beforeEach(() => {
      ({ addShortcutsExtension, markShortcutExtensionReady } = loadModule());
    });

    it('instantiates the extension with the shortcuts instance and args', async () => {
      const Extension = jest.fn();

      await addShortcutsExtension(Extension, 'foo', 'bar');

      expect(Extension).toHaveBeenCalledTimes(1);
      expect(Extension).toHaveBeenCalledWith(expect.anything(), 'foo', 'bar');
    });

    it('records the extension name once the async bundle has bound it', async () => {
      function TestExtension() {}
      expect(document.body.dataset.shortcutsReady).toBeUndefined();

      await addShortcutsExtension(TestExtension);

      expect(document.body.dataset.shortcutsReady).toBe('TestExtension');
    });

    it('appends each additionally bound extension name', async () => {
      function ExtensionA() {}
      function ExtensionB() {}

      await addShortcutsExtension(ExtensionA);
      await addShortcutsExtension(ExtensionB);

      expect(document.body.dataset.shortcutsReady).toBe('ExtensionA ExtensionB');
    });

    describe('markShortcutExtensionReady', () => {
      it('records a name directly, for callers outside the extension system', () => {
        markShortcutExtensionReady('ShortcutsWorkItemNotes');

        expect(document.body.dataset.shortcutsReady).toBe('ShortcutsWorkItemNotes');
      });

      it('does not add the same name twice', () => {
        markShortcutExtensionReady('ShortcutsWorkItemNotes');
        markShortcutExtensionReady('ShortcutsWorkItemNotes');

        expect(document.body.dataset.shortcutsReady).toBe('ShortcutsWorkItemNotes');
      });
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

    it('leaves the shortcuts-ready marker unset, since nothing was bound', async () => {
      function TestExtension() {}

      await addShortcutsExtension(TestExtension);

      expect(document.body.dataset.shortcutsReady).toBeUndefined();
    });
  });
});
