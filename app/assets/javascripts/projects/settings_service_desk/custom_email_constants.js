import { s__, __ } from '~/locale';

export const FEEDBACK_ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/416637';

export const I18N_LOADING_LABEL = __('Loading');
export const I18N_CARD_TITLE = s__('ServiceDesk|Configure a custom email address');
export const I18N_FEEDBACK_PARAGRAPH = s__(
  'ServiceDesk|Please share your feedback on this feature in the %{linkStart}feedback issue%{linkEnd}',
);
export const I18N_GENERIC_ERROR = __('An error occurred. Please try again.');

export const I18N_TOAST_SAVED = s__(
  'ServiceDesk|Saved custom email address and started verification.',
);
export const I18N_TOAST_DELETED = s__('ServiceDesk|Reset custom email address.');
export const I18N_TOAST_ENABLED = s__('ServiceDesk|Custom email enabled.');
export const I18N_TOAST_DISABLED = s__('ServiceDesk|Custom email disabled.');

export const I18N_FORM_INTRODUCTION_PARAGRAPH = s__(
  'ServiceDesk|Connect a custom email address your customers can use to create Service Desk issues. Forward all emails from your custom email address to the Service Desk email address of this project. GitLab will send Service Desk emails from the custom address on your behalf using your SMTP credentials. %{linkStart}Learn more about prerequisites and the verification process%{linkEnd}.',
);
export const I18N_FORM_FORWARDING_LABEL = s__(
  'ServiceDesk|Service Desk email address to forward emails to',
);
export const I18N_FORM_FORWARDING_CLIPBOARD_BUTTON_TITLE = s__(
  'ServiceDesk|Copy Service Desk email address',
);
export const I18N_FORM_CUSTOM_EMAIL_LABEL = s__('ServiceDesk|Custom email address');
export const I18N_FORM_CUSTOM_EMAIL_DESCRIPTION = s__(
  'ServiceDesk|Email address your customers can use to send support requests. It must support sub-addressing.',
);
export const I18N_FORM_SMTP_ADDRESS_LABEL = s__('ServiceDesk|SMTP host');
export const I18N_FORM_SMTP_PORT_LABEL = s__('ServiceDesk|SMTP port');
export const I18N_FORM_SMTP_PORT_DESCRIPTION = s__(
  'ServiceDesk|Common ports are 587 when using TLS, and 25 when not.',
);
export const I18N_FORM_SMTP_USERNAME_LABEL = s__('ServiceDesk|SMTP username');
export const I18N_FORM_SMTP_PASSWORD_LABEL = s__('ServiceDesk|SMTP password');
export const I18N_FORM_SMTP_PASSWORD_DESCRIPTION = s__('ServiceDesk|Minimum 8 characters long.');
export const I18N_FORM_SMTP_AUTHENTICATION_LABEL = s__('ServiceDesk|SMTP authentication method');
export const I18N_FORM_SMTP_AUTHENTICATION_NONE = s__(
  'ServiceDesk|Let GitLab select a server-supported method (recommended)',
);
export const I18N_FORM_SMTP_AUTHENTICATION_PLAIN = s__('ServiceDesk|Plain');
export const I18N_FORM_SMTP_AUTHENTICATION_LOGIN = s__('ServiceDesk|Login');
export const I18N_FORM_SMTP_AUTHENTICATION_CRAM_MD5 = s__('ServiceDesk|CRAM-MD5');
export const I18N_FORM_SUBMIT_LABEL = s__('ServiceDesk|Save and test connection');

export const I18N_FORM_INVALID_FEEDBACK_CUSTOM_EMAIL = s__(
  'ServiceDesk|Custom email is required and must be a valid email address.',
);
export const I18N_FORM_INVALID_FEEDBACK_SMTP_ADDRESS = s__(
  'ServiceDesk|SMTP address is required and must be resolvable.',
);
export const I18N_FORM_INVALID_FEEDBACK_SMTP_PORT = s__(
  'ServiceDesk|SMTP port is required and must be a port number larger than 0.',
);
export const I18N_FORM_INVALID_FEEDBACK_SMTP_USERNAME = s__(
  'ServiceDesk|SMTP username is required.',
);
export const I18N_FORM_INVALID_FEEDBACK_SMTP_PASSWORD = s__(
  'ServiceDesk|SMTP password is required and must be at least 8 characters long.',
);

export const I18N_MODAL_TITLE = s__(
  'ServiceDesk|Reset custom email address and delete credentials',
);
export const I18N_MODAL_CANCEL_BUTTON_LABEL = s__('ServiceDesk|Keep custom email');
export const I18N_MODAL_DISABLE_CUSTOM_EMAIL_PARAGRAPH = s__(
  'ServiceDesk|You are about to %{strongStart}disable the custom email address%{strongEnd} %{customEmail} %{strongStart}and delete its credentials%{strongEnd}.',
);
export const I18N_MODAL_SET_UP_AGAIN_PARAGRAPH = s__(
  "ServiceDesk|To use a custom email address for this Service Desk, you'll need to configure and verify an email address again.",
);

export const I18N_STATE_INTRO_PARAGRAPH = s__(
  'ServiceDesk|Verify %{customEmail} with SMTP host %{smtpAddress}:',
);
export const I18N_STATE_VERIFICATION_STARTED = s__('ServiceDesk|Verification started');
export const I18N_STATE_VERIFICATION_STARTED_RESET_PARAGRAPH = s__(
  'ServiceDesk|A verification email has been sent to a sub-address of your custom email address. This can take up to 30 minutes. The screen refreshes automatically.',
);
export const I18N_RESET_BUTTON_LABEL = s__('ServiceDesk|Reset custom email');

export const I18N_STATE_VERIFICATION_FINISHED_INTRO_PARAGRAPH = s__(
  'ServiceDesk|%{customEmail} with SMTP host %{smtpAddress} is %{badgeStart}verified%{badgeEnd}',
);
export const I18N_STATE_VERIFICATION_FINISHED_TOGGLE_LABEL = s__(
  'ServiceDesk|Enable custom email address',
);
export const I18N_STATE_VERIFICATION_FINISHED_TOGGLE_HELP = s__(
  'ServiceDesk|When enabled, Service Desk emails will be sent using the provided credentials.',
);
export const I18N_STATE_VERIFICATION_FINISHED_RESET_PARAGRAPH = s__(
  'ServiceDesk|Or reset and connect a new custom email address to this Service Desk.',
);

export const I18N_STATE_VERIFICATION_FAILED = s__('ServiceDesk|Verification failed');
export const I18N_STATE_VERIFICATION_FAILED_RESET_PARAGRAPH = s__(
  'ServiceDesk|Please try again. Check email forwarding settings and credentials, and then restart verification.',
);

export const I18N_STATE_RESET_PARAGRAPH = {
  started: I18N_STATE_VERIFICATION_STARTED_RESET_PARAGRAPH,
  failed: I18N_STATE_VERIFICATION_FAILED_RESET_PARAGRAPH,
  finished: I18N_STATE_VERIFICATION_FINISHED_RESET_PARAGRAPH,
};

export const I18N_ERROR_SMTP_HOST_ISSUE_LABEL = s__('ServiceDesk|SMTP host issue');
export const I18N_ERROR_SMTP_HOST_ISSUE_DESC = s__(
  'ServiceDesk|A connection to the specified host could not be made or an SSL issue occurred.',
);
export const I18N_ERROR_INVALID_CREDENTIALS_LABEL = s__('ServiceDesk|Invalid credentials');
export const I18N_ERROR_INVALID_CREDENTIALS_DESC = s__(
  'ServiceDesk|The given credentials (username and password) were rejected by the SMTP server, or you need to explicitly set an authentication method.',
);
export const I18N_ERROR_MAIL_NOT_RECEIVED_IN_TIMEFRAME_LABEL = s__(
  'ServiceDesk|Verification email not received within timeframe',
);
export const I18N_ERROR_MAIL_NOT_RECEIVED_IN_TIMEFRAME_DESC = s__(
  "ServiceDesk|The verification email wasn't received in time. There is a 30 minutes timeframe for verification emails to appear in your instance's Service Desk. Make sure that you have set up email forwarding correctly.",
);
export const I18N_ERROR_INCORRECT_FROM_LABEL = s__('ServiceDesk|Incorrect From header');
export const I18N_ERROR_INCORRECT_FROM_DESC = s__(
  'ServiceDesk|Check your forwarding settings and make sure the original email sender remains in the From header.',
);
export const I18N_ERROR_INCORRECT_TOKEN_LABEL = s__('ServiceDesk|Incorrect verification token');
export const I18N_ERROR_INCORRECT_TOKEN_DESC = s__(
  "ServiceDesk|The received email didn't contain the verification token that was sent to your email address.",
);
export const I18N_ERROR_READ_TIMEOUT_LABEL = s__('ServiceDesk|Read timeout');
export const I18N_ERROR_READ_TIMEOUT_DESC = s__(
  'ServiceDesk|The SMTP server did not respond in time.',
);
export const I18N_ERROR_INCORRECT_FORWARDING_TARGET_LABEL = s__(
  'ServiceDesk|Incorrect forwarding target',
);
export const I18N_ERROR_INCORRECT_FORWARDING_TARGET_DESC = s__(
  'ServiceDesk|Forward all emails to the custom email address to %{incomingEmail}.',
);

export const I18N_VERIFICATION_ERRORS = {
  smtp_host_issue: {
    label: I18N_ERROR_SMTP_HOST_ISSUE_LABEL,
    description: I18N_ERROR_SMTP_HOST_ISSUE_DESC,
  },
  invalid_credentials: {
    label: I18N_ERROR_INVALID_CREDENTIALS_LABEL,
    description: I18N_ERROR_INVALID_CREDENTIALS_DESC,
  },
  mail_not_received_within_timeframe: {
    label: I18N_ERROR_MAIL_NOT_RECEIVED_IN_TIMEFRAME_LABEL,
    description: I18N_ERROR_MAIL_NOT_RECEIVED_IN_TIMEFRAME_DESC,
  },
  incorrect_from: {
    label: I18N_ERROR_INCORRECT_FROM_LABEL,
    description: I18N_ERROR_INCORRECT_FROM_DESC,
  },
  incorrect_token: {
    label: I18N_ERROR_INCORRECT_TOKEN_LABEL,
    description: I18N_ERROR_INCORRECT_TOKEN_DESC,
  },
  read_timeout: {
    label: I18N_ERROR_READ_TIMEOUT_LABEL,
    description: I18N_ERROR_READ_TIMEOUT_DESC,
  },
  incorrect_forwarding_target: {
    label: I18N_ERROR_INCORRECT_FORWARDING_TARGET_LABEL,
    description: I18N_ERROR_INCORRECT_FORWARDING_TARGET_DESC,
  },
};
