function initLabels() {
  const pagination = document.querySelector('.labels .gl-pagination');
  const emptyState = document.querySelector('.labels .nothing-here-block.hidden');

  function removeLabelSuccessCallback() {
    this.closest('li').classList.add('gl-display-none!');

    const labelsCount = document.querySelectorAll(
      'ul.manage-labels-list li:not(.gl-display-none\\!)',
    ).length;

    // display the empty state if there are no more labels
    if (labelsCount < 1 && !pagination && emptyState) {
      emptyState.classList.remove('hidden');
    }
  }

  document.querySelectorAll('.js-remove-label').forEach((row) => {
    row.addEventListener('ajax:success', removeLabelSuccessCallback);
  });
}

initLabels();
