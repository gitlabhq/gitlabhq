export const TEMPLATES = [
  'Project #1',
  [
    { name: 'Bug', project_id: 1 },
    { name: 'Documentation', project_id: 1 },
    { name: 'Security release', project_id: 1 },
  ],
];

export const MOCK_CUSTOM_EMAIL_EMPTY = {
  custom_email: null,
  custom_email_enabled: false,
  custom_email_verification_state: null,
  custom_email_verification_error: null,
  custom_email_smtp_address: null,
  error_message: null,
};

export const MOCK_CUSTOM_EMAIL_STARTED = {
  custom_email: 'user@example.com',
  custom_email_enabled: false,
  custom_email_verification_state: 'started',
  custom_email_verification_error: null,
  custom_email_smtp_address: 'smtp.example.com',
  error_message: null,
};

export const MOCK_CUSTOM_EMAIL_FAILED = {
  custom_email: 'user@example.com',
  custom_email_enabled: false,
  custom_email_verification_state: 'failed',
  custom_email_verification_error: 'smtp_host_issue',
  custom_email_smtp_address: 'smtp.example.com',
  error_message: null,
};

export const MOCK_CUSTOM_EMAIL_FINISHED = {
  custom_email: 'user@example.com',
  custom_email_enabled: false,
  custom_email_verification_state: 'finished',
  custom_email_verification_error: null,
  custom_email_smtp_address: 'smtp.example.com',
  error_message: null,
};

export const MOCK_CUSTOM_EMAIL_ENABLED = {
  custom_email: 'user@example.com',
  custom_email_enabled: true,
  custom_email_verification_state: 'finished',
  custom_email_verification_error: null,
  custom_email_smtp_address: 'smtp.example.com',
  error_message: null,
};

export const MOCK_CUSTOM_EMAIL_DISABLED = {
  custom_email: 'user@example.com',
  custom_email_enabled: false,
  custom_email_verification_state: 'finished',
  custom_email_verification_error: null,
  custom_email_smtp_address: 'smtp.example.com',
  error_message: null,
};

export const MOCK_CUSTOM_EMAIL_FORM_SUBMIT = {
  custom_email: 'user@example.com',
  smtp_address: 'smtp.example.com',
  smtp_password: 'supersecret',
  smtp_port: '587',
  smtp_username: 'user@example.com',
};
