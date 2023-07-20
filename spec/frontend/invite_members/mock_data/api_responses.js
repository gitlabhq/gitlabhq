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

export const IMPORT_PROJECT_MEMBERS_PATH = '/api/v4/projects/1/import_project_members/2';
const EXPANDED_IMPORT_ERRORS = {
  message: {
    bob_smith: 'Something is wrong for this member.',
    john_smith: 'Something is wrong for this member.',
    doug_logan: 'Something is wrong for this member.',
    root: 'Something is wrong for this member.',
  },
  total_members_count: '4',
  status: 'error',
};
const NO_COLLAPSE_IMPORT_ERRORS = {
  message: {
    bob_smith: 'Something is wrong for this member.',
    john_smith: 'Something is wrong for this member.',
  },
  total_members_count: '2',
  status: 'error',
};
export const importProjectMembersApiResponse = {
  EXPANDED_IMPORT_ERRORS,
  NO_COLLAPSE_IMPORT_ERRORS,
};
