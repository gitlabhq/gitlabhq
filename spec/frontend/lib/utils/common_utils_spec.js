import * as cu from '~/lib/utils/common_utils';

const CMD_ENTITY = '&#8984;';

// Redefine `navigator.platform` because it's unsettable by default in JSDOM.
let platform;
Object.defineProperty(navigator, 'platform', {
  configurable: true,
  get: () => platform,
  set: val => {
    platform = val;
  },
});

describe('common_utils', () => {
  describe('platform leader key helpers', () => {
    const CTRL_EVENT = { ctrlKey: true };
    const META_EVENT = { metaKey: true };
    const BOTH_EVENT = { ctrlKey: true, metaKey: true };

    it('should return "ctrl" if navigator.platform is unset', () => {
      expect(cu.getPlatformLeaderKey()).toBe('ctrl');
      expect(cu.getPlatformLeaderKeyHTML()).toBe('Ctrl');
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });

    it('should return "meta" on MacOS', () => {
      navigator.platform = 'MacIntel';
      expect(cu.getPlatformLeaderKey()).toBe('meta');
      expect(cu.getPlatformLeaderKeyHTML()).toBe(CMD_ENTITY);
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });

    it('should return "ctrl" on Linux', () => {
      navigator.platform = 'Linux is great';
      expect(cu.getPlatformLeaderKey()).toBe('ctrl');
      expect(cu.getPlatformLeaderKeyHTML()).toBe('Ctrl');
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });

    it('should return "ctrl" on Windows', () => {
      navigator.platform = 'Win32';
      expect(cu.getPlatformLeaderKey()).toBe('ctrl');
      expect(cu.getPlatformLeaderKeyHTML()).toBe('Ctrl');
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });
  });

  describe('keystroke', () => {
    const CODE_BACKSPACE = 8;
    const CODE_TAB = 9;
    const CODE_ENTER = 13;
    const CODE_SPACE = 32;
    const CODE_4 = 52;
    const CODE_F = 70;
    const CODE_Z = 90;

    // Helper function that quickly creates KeyboardEvents
    const k = (code, modifiers = '') => ({
      keyCode: code,
      which: code,
      altKey: modifiers.includes('a'),
      ctrlKey: modifiers.includes('c'),
      metaKey: modifiers.includes('m'),
      shiftKey: modifiers.includes('s'),
    });

    const EV_F = k(CODE_F);
    const EV_ALT_F = k(CODE_F, 'a');
    const EV_CONTROL_F = k(CODE_F, 'c');
    const EV_META_F = k(CODE_F, 'm');
    const EV_SHIFT_F = k(CODE_F, 's');
    const EV_CONTROL_SHIFT_F = k(CODE_F, 'cs');
    const EV_ALL_F = k(CODE_F, 'scma');
    const EV_ENTER = k(CODE_ENTER);
    const EV_TAB = k(CODE_TAB);
    const EV_SPACE = k(CODE_SPACE);
    const EV_BACKSPACE = k(CODE_BACKSPACE);
    const EV_4 = k(CODE_4);
    const EV_$ = k(CODE_4, 's');

    const { keystroke } = cu;

    it('short-circuits with bad arguments', () => {
      expect(keystroke()).toBe(false);
      expect(keystroke({})).toBe(false);
    });

    it('handles keystrokes using key codes', () => {
      // Test a letter key with modifiers
      expect(keystroke(EV_F, CODE_F)).toBe(true);
      expect(keystroke(EV_F, CODE_F, '')).toBe(true);
      expect(keystroke(EV_ALT_F, CODE_F, 'a')).toBe(true);
      expect(keystroke(EV_CONTROL_F, CODE_F, 'c')).toBe(true);
      expect(keystroke(EV_META_F, CODE_F, 'm')).toBe(true);
      expect(keystroke(EV_SHIFT_F, CODE_F, 's')).toBe(true);
      expect(keystroke(EV_CONTROL_SHIFT_F, CODE_F, 'cs')).toBe(true);
      expect(keystroke(EV_ALL_F, CODE_F, 'acms')).toBe(true);

      // Test non-letter keys
      expect(keystroke(EV_TAB, CODE_TAB)).toBe(true);
      expect(keystroke(EV_ENTER, CODE_ENTER)).toBe(true);
      expect(keystroke(EV_SPACE, CODE_SPACE)).toBe(true);
      expect(keystroke(EV_BACKSPACE, CODE_BACKSPACE)).toBe(true);

      // Test a number/symbol key
      expect(keystroke(EV_4, CODE_4)).toBe(true);
      expect(keystroke(EV_$, CODE_4, 's')).toBe(true);

      // Test wrong input
      expect(keystroke(EV_F, CODE_Z)).toBe(false);
      expect(keystroke(EV_SHIFT_F, CODE_F)).toBe(false);
      expect(keystroke(EV_SHIFT_F, CODE_F, 'c')).toBe(false);
    });

    it('is case-insensitive', () => {
      expect(keystroke(EV_ALL_F, CODE_F, 'ACMS')).toBe(true);
    });

    it('handles bogus inputs', () => {
      expect(keystroke(EV_F, 'not a keystroke')).toBe(false);
      expect(keystroke(EV_F, null)).toBe(false);
    });

    it('handles exact modifier keys, in any order', () => {
      // Test permutations of modifiers
      expect(keystroke(EV_ALL_F, CODE_F, 'acms')).toBe(true);
      expect(keystroke(EV_ALL_F, CODE_F, 'smca')).toBe(true);
      expect(keystroke(EV_ALL_F, CODE_F, 'csma')).toBe(true);
      expect(keystroke(EV_CONTROL_SHIFT_F, CODE_F, 'cs')).toBe(true);
      expect(keystroke(EV_CONTROL_SHIFT_F, CODE_F, 'sc')).toBe(true);

      // Test wrong modifiers
      expect(keystroke(EV_ALL_F, CODE_F, 'smca')).toBe(true);
      expect(keystroke(EV_ALL_F, CODE_F)).toBe(false);
      expect(keystroke(EV_ALL_F, CODE_F, '')).toBe(false);
      expect(keystroke(EV_ALL_F, CODE_F, 'c')).toBe(false);
      expect(keystroke(EV_ALL_F, CODE_F, 'ca')).toBe(false);
      expect(keystroke(EV_ALL_F, CODE_F, 'ms')).toBe(false);
      expect(keystroke(EV_CONTROL_SHIFT_F, CODE_F, 'cs')).toBe(true);
      expect(keystroke(EV_CONTROL_SHIFT_F, CODE_F, 'c')).toBe(false);
      expect(keystroke(EV_CONTROL_SHIFT_F, CODE_F, 's')).toBe(false);
      expect(keystroke(EV_CONTROL_SHIFT_F, CODE_F, 'csa')).toBe(false);
      expect(keystroke(EV_CONTROL_SHIFT_F, CODE_F, 'm')).toBe(false);
      expect(keystroke(EV_SHIFT_F, CODE_F, 's')).toBe(true);
      expect(keystroke(EV_SHIFT_F, CODE_F, 'c')).toBe(false);
      expect(keystroke(EV_SHIFT_F, CODE_F, 'csm')).toBe(false);
    });

    it('handles the platform-dependent leader key', () => {
      navigator.platform = 'Win32';
      let EV_UNDO = k(CODE_Z, 'c');
      let EV_REDO = k(CODE_Z, 'cs');
      expect(keystroke(EV_UNDO, CODE_Z, 'l')).toBe(true);
      expect(keystroke(EV_UNDO, CODE_Z, 'c')).toBe(true);
      expect(keystroke(EV_UNDO, CODE_Z, 'm')).toBe(false);
      expect(keystroke(EV_REDO, CODE_Z, 'sl')).toBe(true);
      expect(keystroke(EV_REDO, CODE_Z, 'sc')).toBe(true);
      expect(keystroke(EV_REDO, CODE_Z, 'sm')).toBe(false);

      navigator.platform = 'MacIntel';
      EV_UNDO = k(CODE_Z, 'm');
      EV_REDO = k(CODE_Z, 'ms');
      expect(keystroke(EV_UNDO, CODE_Z, 'l')).toBe(true);
      expect(keystroke(EV_UNDO, CODE_Z, 'c')).toBe(false);
      expect(keystroke(EV_UNDO, CODE_Z, 'm')).toBe(true);
      expect(keystroke(EV_REDO, CODE_Z, 'sl')).toBe(true);
      expect(keystroke(EV_REDO, CODE_Z, 'sc')).toBe(false);
      expect(keystroke(EV_REDO, CODE_Z, 'sm')).toBe(true);
    });
  });
});
