<script>
import { __, s__ } from '~/locale';

// Map some keys to their proper representation depending on the system
// See also: https://craig.is/killing/mice#keys
const getKeyMap = () => {
  const keyMap = {
    up: '↑',
    down: '↓',
    left: '←',
    right: '→',
    ctrl: s__('KeyboardKey|Ctrl'),
    shift: s__('KeyboardKey|Shift'),
    enter: s__('KeyboardKey|Enter'),
    esc: s__('KeyboardKey|Esc'),
    command: '⌘',
    option: window.gl?.client?.isMac ? '⌥' : s__('KeyboardKey|Alt'),
  };

  // Meta and alt are aliases
  keyMap.meta = keyMap.command;
  keyMap.alt = keyMap.option;

  // Mod is Command on Mac, and Ctrl on Windows/Linux
  keyMap.mod = window.gl?.client?.isMac ? keyMap.command : keyMap.ctrl;

  return keyMap;
};

export default {
  functional: true,
  props: {
    shortcuts: {
      type: Array,
      required: true,
    },
  },

  render(createElement, context) {
    const keyMap = getKeyMap();

    const { staticClass } = context.data;

    const shortcuts = context.props.shortcuts.reduce((acc, shortcut, i) => {
      if (
        !window.gl?.client?.isMac &&
        (shortcut.includes('command') || shortcut.includes('meta'))
      ) {
        return acc;
      }
      const keys = shortcut.split(/([ +])/);

      if (i !== 0 && acc.length) {
        acc.push(` ${__('or')} `);
        // If there are multiple alternative shortcuts,
        // we keep them on the same line if they are single-key, e.g. `]` or `j`
        // but if they consist of multiple keys, we insert a line break, e.g.:
        // `shift` + `]` <br> or `shift` + `j`
        if (keys.length > 1) {
          acc.push(createElement('br'));
        }
      }

      keys.forEach((key) => {
        if (key === '+') {
          acc.push(' + ');
        } else if (key === ' ') {
          acc.push(` ${__('then')} `);
        } else {
          acc.push(createElement('kbd', {}, [keyMap[key] ?? key]));
        }
      });

      return acc;
    }, []);

    return createElement('div', { staticClass }, shortcuts);
  },
};
</script>
