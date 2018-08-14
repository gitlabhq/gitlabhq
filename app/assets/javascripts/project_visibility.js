import $ from 'jquery';

function setVisibilityOptions(namespaceSelector) {
  if (!namespaceSelector || !('selectedIndex' in namespaceSelector)) {
    return;
  }
  const selectedNamespace = namespaceSelector.options[namespaceSelector.selectedIndex];
  const { name, visibility, visibilityLevel, showPath, editPath } = selectedNamespace.dataset;

  document.querySelectorAll('.visibility-level-setting .form-check').forEach((option) => {
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
          reason.innerHTML =
            `This project cannot be ${optionName} because the visibility of
            <a href="${showPath}">${name}</a> is ${visibility}. To make this project
            ${optionName}, you must first <a href="${editPath}">change the visibility</a>
            of the parent group.`;
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
