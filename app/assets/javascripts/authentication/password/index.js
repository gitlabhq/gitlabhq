import Vue from 'vue';
import GlFieldErrors from '~/gl_field_errors';
import PasswordInput from './components/password_input.vue';

export const initPasswordInput = () => {
  document.querySelectorAll('.js-password').forEach((el) => {
    if (!el) {
      return null;
    }

    const { form } = el;
    const { title, id, minimumPasswordLength, testid, autocomplete, name } = el.dataset;

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
            autocomplete,
            name,
          },
        });
      },
    });

    // Since we replaced password input, we need to re-initialize the field errors handler
    return new GlFieldErrors(form);
  });
};
