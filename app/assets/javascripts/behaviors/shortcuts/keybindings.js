import { memoize } from 'lodash';
import AccessorUtilities from '~/lib/utils/accessor';
import { s__ } from '~/locale';

export const LOCAL_STORAGE_KEY = 'gl-keyboard-shortcuts-customizations';

/**
 * @returns { Object.<string, string[]> } A map of command ID => keys of all
 * keyboard shortcuts that have been customized by the user. These
 * customizations are fetched from `localStorage`. This function is memoized,
 * so its return value will not reflect changes made to the `localStorage` data
 * after it has been called once.
 *
 * @example
 * { "globalShortcuts.togglePerformanceBar": ["p e r f"] }
 */
export const getCustomizations = memoize(() => {
  let parsedCustomizations = {};
  const localStorageIsSafe = AccessorUtilities.isLocalStorageAccessSafe();

  if (localStorageIsSafe) {
    try {
      parsedCustomizations = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY) || '{}');
    } catch (e) {
      /* do nothing */
    }
  }

  return parsedCustomizations;
});

// All available commands
export const TOGGLE_PERFORMANCE_BAR = {
  id: 'globalShortcuts.togglePerformanceBar',
  description: s__('KeyboardShortcuts|Toggle the Performance Bar'),
  // eslint-disable-next-line @gitlab/require-i18n-strings
  defaultKeys: ['p b'],
};

export const TOGGLE_CANARY = {
  id: 'globalShortcuts.toggleCanary',
  description: s__('KeyboardShortcuts|Toggle GitLab Next'),
  // eslint-disable-next-line @gitlab/require-i18n-strings
  defaultKeys: ['g x'],
};

export const WEB_IDE_COMMIT = {
  id: 'webIDE.commit',
  description: s__('KeyboardShortcuts|Commit (when editing commit message)'),
  defaultKeys: ['mod+enter'],
  customizable: false,
};

// All keybinding groups
export const GLOBAL_SHORTCUTS_GROUP = {
  id: 'globalShortcuts',
  name: s__('KeyboardShortcuts|Global Shortcuts'),
  keybindings: [TOGGLE_PERFORMANCE_BAR, TOGGLE_CANARY],
};

export const WEB_IDE_GROUP = {
  id: 'webIDE',
  name: s__('KeyboardShortcuts|Web IDE'),
  keybindings: [WEB_IDE_COMMIT],
};

/** All keybindings, grouped and ordered with descriptions */
export const keybindingGroups = [GLOBAL_SHORTCUTS_GROUP, WEB_IDE_GROUP];

/**
 * Gets keyboard shortcuts associated with a command
 *
 * @param {string} command The command object. All command
 * objects are available as imports from this file.
 *
 * @returns {string[]} An array of keyboard shortcut strings bound to the command
 *
 * @example
 * import { keysFor, TOGGLE_PERFORMANCE_BAR } from '~/behaviors/shortcuts/keybindings'
 *
 * Mousetrap.bind(keysFor(TOGGLE_PERFORMANCE_BAR), handler);
 */
export const keysFor = (command) => {
  if (command.customizable === false) {
    // if the command is defined with `customizable: false`,
    // don't allow this command to be customized.
    return command.defaultKeys;
  }

  return getCustomizations()[command.id] || command.defaultKeys;
};
