import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
      'ldapSyncConfigured',
      'samlScimConfigured',
      'contractOveragesAllowed',
    ],
  });

  return initVueApp({
    el,
    name: 'SignupRestrictions',
    provide: {
      ...parsedDataset,
    },
    component: SignupForm,
  });
}
