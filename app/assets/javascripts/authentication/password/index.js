import Vue from 'vue';
import GlFieldErrors from '~/gl_field_errors';
import PasswordInput from './components/password_input.vue';

export const initTogglePasswordVisibility = () => {
  document.querySelectorAll('.js-password').forEach((el) => {
    if (!el) {
      return null;
    }

    const { form } = el;
    const { title, id, minimumPasswordLength, qaSelector, autocomplete, name } = el.dataset;

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
            qaSelector,
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
