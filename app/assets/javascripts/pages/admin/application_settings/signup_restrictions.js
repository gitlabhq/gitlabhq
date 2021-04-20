import Vue from 'vue';
import SignupForm from './general/components/signup_form.vue';
import { getParsedDataset } from './utils';

export default function initSignupRestrictions(elementSelector = '#js-signup-form') {
  const el = document.querySelector(elementSelector);

  if (!el) {
    return false;
  }

  const parsedDataset = getParsedDataset({
    dataset: el.dataset,
    booleanAttributes: [
      'signupEnabled',
      'requireAdminApprovalAfterUserSignup',
      'sendUserConfirmationEmail',
      'domainDenylistEnabled',
      'denylistTypeRawSelected',
      'emailRestrictionsEnabled',
    ],
  });

  return new Vue({
    el,
    provide: {
      ...parsedDataset,
    },
    render: (createElement) => createElement(SignupForm),
  });
}
