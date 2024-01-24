export const getModifierKey = (removeSuffix = false) => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const winKey = `Ctrl${removeSuffix ? '' : '+'}`;
  return window.gl?.client?.isMac ? '⌘' : winKey;
};

export const PRELOAD_THROTTLE_TIMEOUT_MS = 4000;
