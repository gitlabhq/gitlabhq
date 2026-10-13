export const markShortcutExtensionReady = (name) => {
  const readyExtensions = document.body.dataset.shortcutsReady?.split(' ') ?? [];
  if (readyExtensions.includes(name)) return;

  document.body.dataset.shortcutsReady = [...readyExtensions, name].join(' ');
};
