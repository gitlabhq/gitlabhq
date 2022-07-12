import { escape } from 'lodash';
import { __, sprintf } from '~/locale';
import eventHub from '~/projects/new/event_hub';

// Values are from lib/gitlab/visibility_level.rb
const visibilityLevel = {
  private: 0,
  internal: 10,
  public: 20,
};

function setVisibilityOptions({ name, visibility, showPath, editPath }) {
  document.querySelectorAll('.visibility-level-setting .gl-form-radio').forEach((option) => {
    // Don't change anything if the option is restricted by admin
    if (option.classList.contains('restricted')) {
      return;
    }

    const optionInput = option.querySelector('input[type=radio]');
    const optionValue = optionInput ? parseInt(optionInput.value, 10) : 0;

    if (visibilityLevel[visibility] < optionValue) {
      option.classList.add('disabled');
      optionInput.disabled = true;
      const reason = option.querySelector('.option-disabled-reason');
      if (reason) {
        const optionTitle = option.querySelector('.js-visibility-level-radio span');
        const optionName = optionTitle ? optionTitle.innerText.toLowerCase() : '';
        reason.innerHTML = sprintf(
          __(
            'This project cannot be %{visibilityLevel} because the visibility of %{openShowLink}%{name}%{closeShowLink} is %{visibility}. To make this project %{visibilityLevel}, you must first %{openEditLink}change the visibility%{closeEditLink} of the parent group.',
          ),
          {
            visibilityLevel: optionName,
            name: escape(name),
            visibility,
            openShowLink: `<a href="${showPath}">`,
            closeShowLink: '</a>',
            openEditLink: `<a href="${editPath}">`,
            closeEditLink: '</a>',
          },
          false,
        );
      }
    } else {
      option.classList.remove('disabled');
      optionInput.disabled = false;
    }
  });
}

function handleSelect2DropdownChange(namespaceSelector) {
  if (!namespaceSelector || !('selectedIndex' in namespaceSelector)) {
    return;
  }
  const selectedNamespace = namespaceSelector.options[namespaceSelector.selectedIndex];
  setVisibilityOptions(selectedNamespace.dataset);
}

export default function initProjectVisibilitySelector() {
  eventHub.$on('update-visibility', setVisibilityOptions);

  const namespaceSelector = document.querySelector('select.js-select-namespace');
  if (namespaceSelector) {
    const el = document.querySelector('.select2.js-select-namespace');
    el.addEventListener('change', () => handleSelect2DropdownChange(namespaceSelector));
    handleSelect2DropdownChange(namespaceSelector);
  }
}
