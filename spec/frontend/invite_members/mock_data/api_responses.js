const EMAIL_INVALID = {
  message: { error: 'email contains an invalid email address' },
};

const ERROR_EMAIL_INVALID = {
  error: 'email contains an invalid email address',
};

const EMAIL_RESTRICTED = {
  message: {
    'email@example.com':
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.",
  },
  status: 'error',
};

const MULTIPLE_RESTRICTED = {
  message: {
    'email@example.com':
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.",
    'email4@example.com':
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check the Domain denylist.",
    root:
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.",
  },
  status: 'error',
};

const EXPANDED_RESTRICTED = {
  message: {
    'email@example.com':
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.",
    'email4@example.com':
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check the Domain denylist.",
    'email5@example.com':
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check the Domain denylist.",
    root:
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.",
  },
  status: 'error',
};

const EMAIL_TAKEN = {
  message: {
    'email@example.org': "The member's email address has already been taken",
  },
  status: 'error',
};

export const GROUPS_INVITATIONS_PATH = '/api/v4/groups/1/invitations';

export const invitationsApiResponse = {
  EMAIL_INVALID,
  ERROR_EMAIL_INVALID,
  EMAIL_RESTRICTED,
  MULTIPLE_RESTRICTED,
  EMAIL_TAKEN,
  EXPANDED_RESTRICTED,
};
