import { s__ } from '~/locale';

export const I18N_EXPLANATION = s__(
  "IdentityVerification|For added security, you'll need to verify your identity. We've sent a verification code to %{email}",
);
export const I18N_INPUT_LABEL = s__('IdentityVerification|Verification code');
export const I18N_EMAIL_EMPTY_CODE = s__('IdentityVerification|Enter a code.');
export const I18N_EMAIL_INVALID_CODE = s__('IdentityVerification|Please enter a valid code');
export const I18N_SUBMIT_BUTTON = s__('IdentityVerification|Verify code');
export const I18N_RESEND_LINK = s__('IdentityVerification|Resend code');
export const I18N_EMAIL_RESEND_SUCCESS = s__('IdentityVerification|A new code has been sent.');
export const I18N_GENERIC_ERROR = s__(
  'IdentityVerification|Something went wrong. Please try again.',
);

export const VERIFICATION_CODE_REGEX = /^\d{6}$/;
export const SUCCESS_RESPONSE = 'success';
export const FAILURE_RESPONSE = 'failure';
