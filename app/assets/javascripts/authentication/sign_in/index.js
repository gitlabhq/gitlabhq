import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { parseRailsFormFields } from '~/lib/utils/forms';
import SignInForm from './components/sign_in_form.vue';

export const initSignInForm = () => {
  const el = document.getElementById('js-sign-in-form');

  if (!el) return false;

  const railsFields = parseRailsFormFields(el);

  const { appData } = el.dataset;

  const {
    signInPath,
    // This prop is used behind a default disabled feature flag but is required.
    // Fallback to empty string to avoid issues with backwards compatibility across updates
    // https://docs.gitlab.com/development/multi_version_compatibility/
    usersSignInPathPath = '',
    passkeysSignInPath,
    isUnconfirmedEmail,
    newUserConfirmationPath,
    newPasswordPath,
    showCaptcha,
    isRememberMeEnabled,
  } = convertObjectPropsToCamelCase(JSON.parse(appData));

  return new Vue({
    el,
    name: 'SignInFormRoot',
    render(createElement) {
      return createElement(SignInForm, {
        props: {
          railsFields,
          signInPath,
          usersSignInPathPath,
          passkeysSignInPath,
          isUnconfirmedEmail,
          newUserConfirmationPath,
          newPasswordPath,
          showCaptcha,
          isRememberMeEnabled,
        },
      });
    },
  });
};
