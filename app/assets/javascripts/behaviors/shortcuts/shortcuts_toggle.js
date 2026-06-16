import { Mousetrap } from '~/lib/mousetrap';
import 'mousetrap/plugins/pause/mousetrap-pause';

export { shouldDisableShortcuts } from './shortcuts_disabled';

const shorcutsDisabledKey = 'shortcutsDisabled';

export function enableShortcuts() {
  localStorage.setItem(shorcutsDisabledKey, false);
  Mousetrap.unpause();
}

export function disableShortcuts() {
  localStorage.setItem(shorcutsDisabledKey, true);
  Mousetrap.pause();
}
