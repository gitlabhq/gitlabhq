import Vue from 'vue';
import GlFieldErrors from '~/gl_field_errors';
import PasswordInput from './components/password_input.vue';

export const initTogglePasswordVisibility = () => {
  const el = document.querySelector('.js-password');

  if (!el) {
    return null;
  }

  const { form } = el;
  const { resourceName, minimumPasswordLength, qaSelector } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'PasswordInputRoot',
    render(createElement) {
      return createElement(PasswordInput, {
        props: {
          resourceName,
          minimumPasswordLength,
          qaSelector,
        },
      });
    },
  });

  // Since we replaced password input, we need to re-initialize the field errors handler
  return new GlFieldErrors(form);
};
