import { Mousetrap } from '~/lib/mousetrap';
import 'mousetrap/plugins/pause/mousetrap-pause';

const shorcutsDisabledKey = 'shortcutsDisabled';

export const shouldDisableShortcuts = () => !window.gon.keyboard_shortcuts_enabled;

export function enableShortcuts() {
  localStorage.setItem(shorcutsDisabledKey, false);
  Mousetrap.unpause();
}

export function disableShortcuts() {
  localStorage.setItem(shorcutsDisabledKey, true);
  Mousetrap.pause();
}
