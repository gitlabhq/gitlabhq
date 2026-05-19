export default function initClonePanel() {
  const cloneOptions = document.querySelectorAll('ul.clone-options-dropdown');
  if (!cloneOptions.length) return;

  const cloneUrlField = document.getElementById('clone_url');
  const cloneBtnLabel = document.querySelector('.js-git-clone-holder .js-clone-dropdown-label');
  const mobileCloneField = document.querySelector('.js-mobile-git-clone .js-clone-dropdown-label');

  const selectedCloneOption = cloneBtnLabel?.textContent.trim() ?? '';
  if (selectedCloneOption.length > 0) {
    document.querySelectorAll('ul.clone-options-dropdown a').forEach((anchor) => {
      if (anchor.textContent.includes(selectedCloneOption)) {
        anchor.classList.add('is-active');
      }
    });
  }

  const handleCloneLinkClick = (e) => {
    const target = e.currentTarget;
    const url = target.getAttribute('href');
    if (
      url &&
      (url.startsWith('vscode://') || url.startsWith('xcode://') || url.startsWith('jetbrains://'))
    ) {
      // Clone with "..." should open like a normal link
      return;
    }
    e.preventDefault();
    const { cloneType } = target.dataset;

    document
      .querySelectorAll('ul.clone-options-dropdown .is-active')
      .forEach((el) => el.classList.remove('is-active'));

    document.querySelectorAll(`a[data-clone-type="${cloneType}"]`).forEach((el) => {
      const activeText = el.querySelector('.dropdown-menu-inner-title')?.textContent ?? '';
      const container = el.closest('.js-git-clone-holder, .js-mobile-git-clone');
      const label = container?.querySelector('.js-clone-dropdown-label');

      el.classList.toggle('is-active');
      if (label) label.textContent = activeText;
    });

    if (mobileCloneField) {
      mobileCloneField.dataset.clipboardText = url;
    } else if (cloneUrlField) {
      cloneUrlField.value = url;
    }
    document.querySelectorAll('.js-git-empty .js-clone').forEach((el) => {
      el.textContent = url;
    });
  };

  document.querySelectorAll('ul.clone-options-dropdown .js-clone-links a').forEach((anchor) => {
    anchor.addEventListener('click', handleCloneLinkClick);
  });
}
