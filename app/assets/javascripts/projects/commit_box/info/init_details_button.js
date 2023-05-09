export const initDetailsButton = () => {
  const expandButton = document.querySelector('.js-details-expand');

  if (!expandButton) {
    return;
  }

  expandButton.addEventListener('click', (event) => {
    const btn = event.target;
    const contentEl = btn.parentElement.querySelector('.js-details-content');

    if (contentEl) {
      contentEl.classList.remove('hide');
      btn.classList.add('gl-display-none');
    }
  });
};
