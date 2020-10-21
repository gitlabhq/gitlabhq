import { useLocalStorageSpy } from 'helpers/local_storage_helper';

describe('~/behaviors/shortcuts/keybindings.js', () => {
  let keysFor;
  let TOGGLE_PERFORMANCE_BAR;
  let LOCAL_STORAGE_KEY;

  beforeAll(() => {
    useLocalStorageSpy();
  });

  const setupCustomizations = async customizationsAsString => {
    localStorage.clear();

    if (customizationsAsString) {
      localStorage.setItem(LOCAL_STORAGE_KEY, customizationsAsString);
    }

    jest.resetModules();
    ({ keysFor, TOGGLE_PERFORMANCE_BAR, LOCAL_STORAGE_KEY } = await import(
      '~/behaviors/shortcuts/keybindings'
    ));
  };

  describe('when a command has not been customized', () => {
    beforeEach(async () => {
      await setupCustomizations('{}');
    });

    it('returns the default keybinding for the command', () => {
      expect(keysFor(TOGGLE_PERFORMANCE_BAR)).toEqual(['p b']);
    });
  });

  describe('when a command has been customized', () => {
    const customization = ['p b a r'];

    beforeEach(async () => {
      await setupCustomizations(JSON.stringify({ [TOGGLE_PERFORMANCE_BAR]: customization }));
    });

    it('returns the default keybinding for the command', () => {
      expect(keysFor(TOGGLE_PERFORMANCE_BAR)).toEqual(customization);
    });
  });

  describe("when the localStorage entry isn't valid JSON", () => {
    beforeEach(async () => {
      await setupCustomizations('{');
    });

    it('returns the default keybinding for the command', () => {
      expect(keysFor(TOGGLE_PERFORMANCE_BAR)).toEqual(['p b']);
    });
  });

  describe(`when localStorage doesn't contain the ${LOCAL_STORAGE_KEY} key`, () => {
    beforeEach(async () => {
      await setupCustomizations();
    });

    it('returns the default keybinding for the command', () => {
      expect(keysFor(TOGGLE_PERFORMANCE_BAR)).toEqual(['p b']);
    });
  });
});
