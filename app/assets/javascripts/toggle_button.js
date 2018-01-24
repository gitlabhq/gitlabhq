import $ from 'jquery';
import Vue from 'vue';
import Flash from './flash';
import { __ } from './locale';
import { convertPermissionToBoolean } from './lib/utils/common_utils';
import toggleButton from './vue_shared/components/toggle_button.vue';

/*
 Example HAML:
  ```
  %input{ type: "hidden", class: 'js-project-feature-toggle', value: enabled? }
  ```

  Example JS:
  ```
  const toggleButton = new ToggleButton(
    document.querySelector('.js-project-feature-toggle'),
    (newValue, toggle) => { console.log('toggle clicked', newValue); },
  );
  toggleButton.init();
  ```
*/

export default class ToggleButton {
  constructor(toggle, clickCallback = $.noop) {
    this.toggle = toggle;
    this.clickCallback = clickCallback;

    this.state = {
      name: toggle.getAttribute('name'),
      value: convertPermissionToBoolean(toggle.value),
      isDisabled: !!toggle.getAttribute('disabled'),
      isLoading: false,
    };
  }

  init() {
    const state = this.state;
    const onToggleClicked = this.onToggleClicked.bind(this);

    // eslint-disable-next-line no-new
    new Vue({
      el: this.toggle,
      components: {
        toggleButton,
      },
      data() {
        return {
          state,
        };
      },
      render(createElement) {
        return createElement('toggleButton', {
          props: {
            name: this.state.name,
            value: this.state.value,
            disabledInput: this.state.isDisabled,
            isLoading: this.state.isLoading,
          },
          on: {
            change: onToggleClicked,
          },
        });
      },
    });
  }

  onToggleClicked(newValue) {
    // Visually change the toggle and start loading
    this.setValue(newValue);
    this.setDisabled(true);
    this.setLoading(true);

    Promise.resolve(this.clickCallback(newValue))
      .catch(() => {
        // Revert the visuals if something goes wrong
        this.setValue(!newValue);
      })
      .then(() => {
        // Remove the loading indicator in any case
        this.setDisabled(false);
        this.setLoading(false);
      })
      .catch(() => {
        Flash(__('Something went wrong when toggling the button'));
      });
  }

  setValue(value) {
    this.state.value = value;
  }

  setDisabled(value) {
    this.state.isDisabled = value;
  }

  setLoading(value) {
    this.state.isLoading = value;
  }
}
