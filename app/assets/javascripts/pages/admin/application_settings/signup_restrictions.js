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
      'domainDenylistEnabled',
      'denylistTypeRawSelected',
      'emailRestrictionsEnabled',
      'passwordNumberRequired',
      'passwordLowercaseRequired',
      'passwordUppercaseRequired',
      'passwordSymbolRequired',
      'promotionManagementAvailable',
      'enableMemberPromotionManagement',
      'canDisableMemberPromotionManagement',
    ],
  });

  return new Vue({
    el,
    name: 'SignupRestrictions',
    provide: {
      ...parsedDataset,
    },
    render: (createElement) => createElement(SignupForm),
  });
}
