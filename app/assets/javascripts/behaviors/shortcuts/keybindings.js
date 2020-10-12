import { flatten } from 'lodash';
import { s__ } from '~/locale';
import AccessorUtilities from '~/lib/utils/accessor';
import { shouldDisableShortcuts } from './shortcuts_toggle';

export const LOCAL_STORAGE_KEY = 'gl-keyboard-shortcuts-customizations';

let parsedCustomizations = {};
const localStorageIsSafe = AccessorUtilities.isLocalStorageAccessSafe();

if (localStorageIsSafe) {
  try {
    parsedCustomizations = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY) || '{}');
  } catch (e) {
    /* do nothing */
  }
}

/**
 * A map of command => keys of all keyboard shortcuts
 * that have been customized by the user.
 *
 * @example
 * { "globalShortcuts.togglePerformanceBar": ["p e r f"] }
 *
 * @type { Object.<string, string[]> }
 */
export const customizations = parsedCustomizations;

// All available commands
export const TOGGLE_PERFORMANCE_BAR = 'globalShortcuts.togglePerformanceBar';

/** All keybindings, grouped and ordered with descriptions */
export const keybindingGroups = [
  {
    groupId: 'globalShortcuts',
    name: s__('KeyboardShortcuts|Global Shortcuts'),
    keybindings: [
      {
        description: s__('KeyboardShortcuts|Toggle the Performance Bar'),
        command: TOGGLE_PERFORMANCE_BAR,
        // eslint-disable-next-line @gitlab/require-i18n-strings
        defaultKeys: ['p b'],
      },
    ],
  },
]

  // For each keybinding object, add a `customKeys` property populated with the
  // user's custom keybindings (if the command has been customized).
  // `customKeys` will be `undefined` if the command hasn't been customized.
  .map(group => {
    return {
      ...group,
      keybindings: group.keybindings.map(binding => ({
        ...binding,
        customKeys: customizations[binding.command],
      })),
    };
  });

/**
 * A simple map of command => keys. All user customizations are included in this map.
 * This mapping is used to simplify `keysFor` below.
 *
 * @example
 * { "globalShortcuts.togglePerformanceBar": ["p e r f"] }
 */
const commandToKeys = flatten(keybindingGroups.map(group => group.keybindings)).reduce(
  (acc, binding) => {
    acc[binding.command] = binding.customKeys || binding.defaultKeys;
    return acc;
  },
  {},
);

/**
 * Gets keyboard shortcuts associated with a command
 *
 * @param {string} command The command string. All command
 * strings are available as imports from this file.
 *
 * @returns {string[]} An array of keyboard shortcut strings bound to the command
 *
 * @example
 * import { keysFor, TOGGLE_PERFORMANCE_BAR } from '~/behaviors/shortcuts/keybindings'
 *
 * Mousetrap.bind(keysFor(TOGGLE_PERFORMANCE_BAR), handler);
 */
export const keysFor = command => {
  if (shouldDisableShortcuts()) {
    return [];
  }

  return commandToKeys[command];
};
