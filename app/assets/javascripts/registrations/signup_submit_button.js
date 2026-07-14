import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import SignupSubmitButton from 'ee_else_ce/registrations/components/signup_submit_button.vue';

export const initSignupSubmitButton = () =>
  initSimpleApp('#js-signup-submit-button', SignupSubmitButton, {
    name: 'SignupSubmitButtonRoot',
  });
