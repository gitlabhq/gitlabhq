export const getModifierKey = (removeSuffix = false) => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  const winKey = `Ctrl${removeSuffix ? '' : '+'}`;
  return window.gl?.client?.isMac ? '⌘' : winKey;
};
