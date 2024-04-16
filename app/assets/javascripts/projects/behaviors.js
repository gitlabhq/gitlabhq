import Shortcuts from '~/behaviors/shortcuts/shortcuts';

export const initFindFileShortcut = () => {
  const findFileButton = document.querySelector('.shortcuts-find-file');
  if (!findFileButton) return;
  findFileButton.addEventListener('click', Shortcuts.focusSearchFile);
};
