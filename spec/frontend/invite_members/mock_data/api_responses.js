const INVITATIONS_API_EMAIL_INVALID = {
  message: { error: 'email contains an invalid email address' },
};

const INVITATIONS_API_ERROR_EMAIL_INVALID = {
  error: 'email contains an invalid email address',
};

const INVITATIONS_API_EMAIL_RESTRICTED = {
  message: {
    'email@example.com':
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.",
  },
  status: 'error',
};

const INVITATIONS_API_MULTIPLE_EMAIL_RESTRICTED = {
  message: {
    'email@example.com':
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.",
    'email4@example.com':
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check the Domain denylist.",
  },
  status: 'error',
};

const INVITATIONS_API_EMAIL_TAKEN = {
  message: {
    'email@example.org': 'Invite email has already been taken',
  },
  status: 'error',
};

const MEMBERS_API_MEMBER_ALREADY_EXISTS = {
  message: 'Member already exists',
};

const MEMBERS_API_SINGLE_USER_RESTRICTED = {
  message: {
    user: [
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.",
    ],
  },
};

const MEMBERS_API_SINGLE_USER_ACCESS_LEVEL = {
  message: {
    access_level: [
      'should be greater than or equal to Owner inherited membership from group Gitlab Org',
    ],
  },
};

const MEMBERS_API_MULTIPLE_USERS_RESTRICTED = {
  message:
    "root: The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups. and user18: The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check the Domain denylist. and john_doe31: The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Email restrictions for sign-ups.",
  status: 'error',
};

export const apiPaths = {
  GROUPS_MEMBERS: '/api/v4/groups/1/members',
  GROUPS_INVITATIONS: '/api/v4/groups/1/invitations',
};

export const membersApiResponse = {
  MEMBER_ALREADY_EXISTS: MEMBERS_API_MEMBER_ALREADY_EXISTS,
  SINGLE_USER_ACCESS_LEVEL: MEMBERS_API_SINGLE_USER_ACCESS_LEVEL,
  SINGLE_USER_RESTRICTED: MEMBERS_API_SINGLE_USER_RESTRICTED,
  MULTIPLE_USERS_RESTRICTED: MEMBERS_API_MULTIPLE_USERS_RESTRICTED,
};

export const invitationsApiResponse = {
  EMAIL_INVALID: INVITATIONS_API_EMAIL_INVALID,
  ERROR_EMAIL_INVALID: INVITATIONS_API_ERROR_EMAIL_INVALID,
  EMAIL_RESTRICTED: INVITATIONS_API_EMAIL_RESTRICTED,
  MULTIPLE_EMAIL_RESTRICTED: INVITATIONS_API_MULTIPLE_EMAIL_RESTRICTED,
  EMAIL_TAKEN: INVITATIONS_API_EMAIL_TAKEN,
};
