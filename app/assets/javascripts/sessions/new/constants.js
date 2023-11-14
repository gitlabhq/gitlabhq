import { s__, __ } from '~/locale';

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

export const I18N_EMAIL = __('Email');
export const I18N_UPDATE_EMAIL = s__('IdentityVerification|Update email');
export const I18N_UPDATE_EMAIL_GUIDANCE = s__(
  "EmailVerification|Update your email to a valid permanent address. If you use a temporary email, you won't be able to sign in later.",
);
export const I18N_CANCEL = __('Cancel');
export const I18N_EMAIL_INVALID = s__('IdentityVerification|Please enter a valid email address.');
export const I18N_UPDATE_EMAIL_SUCCESS = s__(
  'IdentityVerification|A new code has been sent to your updated email address.',
);

export const VERIFICATION_CODE_REGEX = /^\d{6}$/;
export const SUCCESS_RESPONSE = 'success';
export const FAILURE_RESPONSE = 'failure';
