import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import GlFieldErrors from '~/gl_field_errors';
import PasswordInput from './components/password_input.vue';

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
    } = el.dataset;

    const requiredAttr = required ? parseBoolean(required) : true;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      name: 'PasswordInputRoot',
      render(createElement) {
        return createElement(PasswordInput, {
          props: {
            title,
            id,
            minimumPasswordLength,
            testid,
            trackActionForErrors,
            autocomplete,
            name,
            required: requiredAttr,
          },
        });
      },
    });

    // Since we replaced password input, we need to re-initialize the field errors handler
    return new GlFieldErrors(form);
  });
};
