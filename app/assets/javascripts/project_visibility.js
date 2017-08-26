function setVisibilityOptions(namespaceSelector) {
  if (!namespaceSelector || !('selectedIndex' in namespaceSelector)) {
    return;
  }
  const selectedNamespace = namespaceSelector.options[namespaceSelector.selectedIndex];
  const { name, visibility, visibilityLevel } = selectedNamespace.dataset;

  document.querySelectorAll('.visibility-level-setting .radio').forEach((option) => {
    const optionInput = option.querySelector('input[type=radio]');
    const optionValue = optionInput ? optionInput.value : 0;
    const optionTitle = option.querySelector('.option-title');
    const optionName = optionTitle ? optionTitle.innerText.toLowerCase() : '';

    // don't change anything if the option is restricted by admin
    if (!option.classList.contains('restricted')) {
      if (visibilityLevel < optionValue) {
        option.classList.add('disabled');
        optionInput.disabled = true;
        const reason = option.querySelector('.option-disabled-reason');
        if (reason) {
          reason.innerText = `This project cannot be ${optionName} because the visibility of ${name} is ${visibility}.`;
        }
      } else {
        option.classList.remove('disabled');
        optionInput.disabled = false;
      }
    }
  });
}

export default function initProjectVisibilitySelector() {
  const namespaceSelector = document.querySelector('select.js-select-namespace');
  if (namespaceSelector) {
    $('.select2.js-select-namespace').on('change', () => setVisibilityOptions(namespaceSelector));
    setVisibilityOptions(namespaceSelector);
  }
}
