import { GlFormPasswordInput } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '@gitlab/frontend-utils';
import GlFieldErrors from '~/gl_field_errors';

export const initPasswordInput = () => {
  document.querySelectorAll('.js-password').forEach((el) => {
    if (!el) {
      return null;
    }

    const { form } = el;

    const {
      title,
      id,
      minimumPasswordLength,
      testid,
      trackActionForErrors,
      required,
      autocomplete,
      name,
      disabled,
    } = el.dataset;

    const requiredAttr = required ? parseBoolean(required) : true;
    const disabledAttr = disabled ? parseBoolean(disabled) : false;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      name: 'PasswordInputRoot',
      render(createElement) {
        // Without this wrapper GlFieldErrors injects the validation message
        // between the input and its reveal toggle, inside the field box.
        return createElement('div', { staticClass: 'gl-field-error-anchor' }, [
          createElement(GlFormPasswordInput, {
            props: {
              disabled: disabledAttr,
              inputClass: 'js-password-complexity-validation js-track-error',
            },
            attrs: {
              id,
              name,
              title,
              required: requiredAttr,
              autocomplete: autocomplete || 'current-password',
              minlength: minimumPasswordLength,
              'data-testid': testid,
              'data-track-action-for-errors': trackActionForErrors,
            },
          }),
        ]);
      },
    });

    // Since we replaced password input, we need to re-initialize the field errors handler
    return new GlFieldErrors(form);
  });
};
