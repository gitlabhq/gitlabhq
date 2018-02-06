import $ from 'jquery';
import Flash from './flash';
import { __ } from './locale';
import { convertPermissionToBoolean } from './lib/utils/common_utils';

/*
 example HAML:
 ```
  %button.js-project-feature-toggle.project-feature-toggle{ type: "button",
    class: "#{'is-checked' if enabled?}",
    'aria-label': _('Toggle Kubernetes Cluster') }
    %input{ type: "hidden", class: 'js-project-feature-toggle-input', value: enabled? }
  ```
*/

function updateToggle(toggle, isOn) {
  toggle.classList.toggle('is-checked', isOn);
}

function onToggleClicked(toggle, input, clickCallback) {
  const previousIsOn = convertPermissionToBoolean(input.value);

  // Visually change the toggle and start loading
  updateToggle(toggle, !previousIsOn);
  toggle.setAttribute('disabled', true);
  toggle.classList.toggle('is-loading', true);

  Promise.resolve(clickCallback(!previousIsOn, toggle))
    .then(() => {
      // Actually change the input value
      input.setAttribute('value', !previousIsOn);
    })
    .catch(() => {
      // Revert the visuals if something goes wrong
      updateToggle(toggle, previousIsOn);
    })
    .then(() => {
      // Remove the loading indicator in any case
      toggle.removeAttribute('disabled');
      toggle.classList.toggle('is-loading', false);

      $(input).trigger('trigger-change');
    })
    .catch(() => {
      Flash(__('Something went wrong when toggling the button'));
    });
}

export default function setupToggleButtons(container, clickCallback = () => {}) {
  const toggles = container.querySelectorAll('.js-project-feature-toggle');

  toggles.forEach((toggle) => {
    const input = toggle.querySelector('.js-project-feature-toggle-input');
    const isOn = convertPermissionToBoolean(input.value);

    // Get the visible toggle in sync with the hidden input
    updateToggle(toggle, isOn);

    toggle.addEventListener('click', onToggleClicked.bind(null, toggle, input, clickCallback));
  });
}
