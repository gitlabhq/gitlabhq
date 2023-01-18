/* eslint-disable @gitlab/require-i18n-strings */

export const getModifierKey = (removeSuffix = false) => {
  const winKey = `Ctrl${removeSuffix ? '' : '+'}`;
  return window.gl?.client?.isMac ? '⌘' : winKey;
};
