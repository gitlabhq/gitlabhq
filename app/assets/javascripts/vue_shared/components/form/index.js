import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import InputCopyToggleVisibility from './input_copy_toggle_visibility.vue';

export function initInputCopyToggleVisibility() {
  const els = document.getElementsByClassName('js-input-copy-visibility');

  Array.from(els).forEach((el) => {
    const {
      name,
      value,
      initialVisibility,
      showToggleVisibilityButton,
      showCopyButton,
      copyButtonTitle,
      readonly,
      formInputGroupProps,
      formGroupAttributes,
    } = el.dataset;

    const parsedFormInputGroupProps = convertObjectPropsToCamelCase(
      JSON.parse(formInputGroupProps || '{}'),
    );
    const parsedFormGroupAttributes = convertObjectPropsToCamelCase(
      JSON.parse(formGroupAttributes || '{}'),
    );

    return new Vue({
      el,
      data() {
        return {
          value,
        };
      },
      render(createElement) {
        return createElement(InputCopyToggleVisibility, {
          props: {
            value: this.value,
            initialVisibility,
            showToggleVisibilityButton,
            showCopyButton,
            copyButtonTitle,
            readonly,
            formInputGroupProps: {
              name,
              ...parsedFormInputGroupProps,
            },
          },
          attrs: parsedFormGroupAttributes,
          on: {
            input: (newValue) => {
              this.value = newValue;
            },
          },
        });
      },
    });
  });
}
