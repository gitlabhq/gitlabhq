const shortcutsPromise = import(/* webpackChunkName: 'shortcutsBundle' */ './shortcuts')
  .then(({ default: Shortcuts }) => new Shortcuts())
  // Fall back to a no-op instance when the chunk fails to load so callers
  // never crash on `undefined` (shortcuts are optional).
  .catch(() => ({ addExtension: () => {}, extensions: new Map() }));

export const addShortcutsExtension = (ShortcutExtension, ...args) =>
  shortcutsPromise.then((shortcuts) => shortcuts.addExtension(ShortcutExtension, args));

export const resetShortcutsForTests = async () => {
  if (process.env.NODE_ENV === 'test') {
    const { Mousetrap, clearStopCallbacksForTests } = await import('~/lib/mousetrap');
    clearStopCallbacksForTests();
    Mousetrap.reset();
    const shortcuts = await shortcutsPromise;
    shortcuts.extensions.clear();
  }
};
