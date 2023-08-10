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

export const I18N_FORM_INTRODUCTION_PARAGRAPH = s__(
  'ServiceDesk|Connect a custom email address your customers can use to create Service Desk issues. Forward all emails from your custom email address to the Service Desk email address of this project. GitLab will send Service Desk emails from the custom address on your behalf using your SMTP credentials.',
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
