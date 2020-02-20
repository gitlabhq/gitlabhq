import Mousetrap from 'mousetrap';
import 'mousetrap/plugins/pause/mousetrap-pause';

const shorcutsDisabledKey = 'shortcutsDisabled';

export const shouldDisableShortcuts = () => {
  try {
    return localStorage.getItem(shorcutsDisabledKey) === 'true';
  } catch (e) {
    return false;
  }
};

export function enableShortcuts() {
  localStorage.setItem(shorcutsDisabledKey, false);
  Mousetrap.unpause();
}

export function disableShortcuts() {
  localStorage.setItem(shorcutsDisabledKey, true);
  Mousetrap.pause();
}
