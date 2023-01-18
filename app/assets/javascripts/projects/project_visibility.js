import { escape } from 'lodash';
import { __, sprintf } from '~/locale';
import eventHub from '~/projects/new/event_hub';
import { VISIBILITY_LEVELS_STRING_TO_INTEGER } from '~/visibility_level/constants';

function setVisibilityOptions({ name, visibility, showPath, editPath }) {
  document.querySelectorAll('.visibility-level-setting .gl-form-radio').forEach((option) => {
    // Don't change anything if the option is restricted by admin
    if (option.classList.contains('restricted')) {
      return;
    }

    const optionInput = option.querySelector('input[type=radio]');
    const optionValue = optionInput ? parseInt(optionInput.value, 10) : 0;

    if (VISIBILITY_LEVELS_STRING_TO_INTEGER[visibility] < optionValue) {
      option.classList.add('disabled');
      optionInput.disabled = true;
      const reason = option.querySelector('.option-disabled-reason');
      if (reason) {
        const optionTitle = option.querySelector('.js-visibility-level-radio span');
        const optionName = optionTitle ? optionTitle.innerText.toLowerCase() : '';
        // eslint-disable-next-line no-unsanitized/property
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

export default function initProjectVisibilitySelector() {
  eventHub.$on('update-visibility', setVisibilityOptions);
}
