import { flatten } from 'lodash';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import {
  keysFor,
  getCustomizations,
  keybindingGroups,
  TOGGLE_PERFORMANCE_BAR,
  HIDE_APPEARING_CONTENT,
  LOCAL_STORAGE_KEY,
  BOLD_TEXT,
} from '~/behaviors/shortcuts/keybindings';

describe('~/behaviors/shortcuts/keybindings', () => {
  useLocalStorageSpy();

  const setupCustomizations = (customizationsAsString) => {
    localStorage.clear();

    if (customizationsAsString) {
      localStorage.setItem(LOCAL_STORAGE_KEY, customizationsAsString);
    }

    getCustomizations.cache.clear();
  };

  describe('keybinding definition errors', () => {
    beforeEach(() => {
      setupCustomizations();
    });

    it('has no duplicate group IDs', () => {
      const allGroupIds = keybindingGroups.map((group) => group.id);
      expect(allGroupIds).toHaveLength(new Set(allGroupIds).size);
    });

    it('has no duplicate commands IDs', () => {
      const allCommandIds = flatten(
        keybindingGroups.map((group) => group.keybindings.map((kb) => kb.id)),
      );
      expect(allCommandIds).toHaveLength(new Set(allCommandIds).size);
    });
  });

  describe('when a command has not been customized', () => {
    beforeEach(() => {
      setupCustomizations('{}');
    });

    it('returns the default keybindings for the command', () => {
      expect(keysFor(TOGGLE_PERFORMANCE_BAR)).toEqual(['p b']);
    });
  });

  describe('when a command has been customized', () => {
    const customization = ['p b a r'];

    beforeEach(() => {
      setupCustomizations(JSON.stringify({ [TOGGLE_PERFORMANCE_BAR.id]: customization }));
    });

    it('returns the custom keybindings for the command', () => {
      expect(keysFor(TOGGLE_PERFORMANCE_BAR)).toEqual(customization);
    });
  });

  describe('when a command is marked as non-customizable', () => {
    const customization = ['mod+shift+c'];

    beforeEach(() => {
      setupCustomizations(JSON.stringify({ [BOLD_TEXT.id]: customization }));
    });

    it('returns the default keybinding for the command', () => {
      expect(keysFor(BOLD_TEXT)).toEqual(['mod+b']);
    });
  });

  describe("when the localStorage entry isn't valid JSON", () => {
    beforeEach(() => {
      setupCustomizations('{');
    });

    it('returns the default keybinding for the command', () => {
      expect(keysFor(TOGGLE_PERFORMANCE_BAR)).toEqual(['p b']);
    });
  });

  describe(`when localStorage doesn't contain the ${LOCAL_STORAGE_KEY} key`, () => {
    beforeEach(() => {
      setupCustomizations();
    });

    it('returns the default keybinding for the command', () => {
      expect(keysFor(TOGGLE_PERFORMANCE_BAR)).toEqual(['p b']);
    });
  });

  describe('when tooltips or popovers are visible', () => {
    beforeEach(() => {
      setupCustomizations();
    });

    it('returns the default keybinding for the command', () => {
      expect(keysFor(HIDE_APPEARING_CONTENT)).toEqual(['esc']);
    });
  });
});
