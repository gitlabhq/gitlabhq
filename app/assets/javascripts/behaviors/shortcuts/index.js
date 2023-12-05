const shortcutsPromise = import(/* webpackChunkName: 'shortcutsBundle' */ './shortcuts')
  .then(({ default: Shortcuts }) => new Shortcuts())
  .catch(() => {});

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
