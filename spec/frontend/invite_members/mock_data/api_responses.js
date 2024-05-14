const EMAIL_INVALID = {
  message: { error: 'email contains an invalid email address' },
};

const ERROR_EMAIL_INVALID = {
  error: 'email contains an invalid email address',
};

const BASE_ERROR_MEMBER_NOT_ALLOWED = `The member's email address is not allowed for this project. \
Go to the &#39;Admin area &gt; Sign-up restrictions&#39;, and check`;

const ALLOWED_DOMAIN_ERROR = `${BASE_ERROR_MEMBER_NOT_ALLOWED} &#39;Allowed domains for sign-ups&#39;.`;
const DOMAIN_DENYLIST_ERROR = `${BASE_ERROR_MEMBER_NOT_ALLOWED} the &#39;Domain denylist&#39;.`;

function htmlDecode(input) {
  const doc = new DOMParser().parseFromString(input, 'text/html');
  return doc.documentElement.textContent;
}

const DECODED_ALLOWED_DOMAIN_ERROR = htmlDecode(ALLOWED_DOMAIN_ERROR);
const DECODED_DOMAIN_DENYLIST_ERROR = htmlDecode(DOMAIN_DENYLIST_ERROR);

const EMAIL_RESTRICTED = {
  message: {
    'email@example.com': ALLOWED_DOMAIN_ERROR,
  },
  parsedMessage: {
    'email@example.com': DECODED_ALLOWED_DOMAIN_ERROR,
  },
  status: 'error',
};

const MULTIPLE_RESTRICTED = {
  message: {
    'email@example.com': ALLOWED_DOMAIN_ERROR,
    'email4@example.com': DOMAIN_DENYLIST_ERROR,
    root: ALLOWED_DOMAIN_ERROR,
  },
  parsedMessage: {
    'email@example.com': DECODED_ALLOWED_DOMAIN_ERROR,
    'email4@example.com': DECODED_DOMAIN_DENYLIST_ERROR,
    root: DECODED_ALLOWED_DOMAIN_ERROR,
  },
  status: 'error',
};

const EXPANDED_RESTRICTED = {
  message: {
    'email@example.com': ALLOWED_DOMAIN_ERROR,
    'email4@example.com': DOMAIN_DENYLIST_ERROR,
    'email5@example.com': DOMAIN_DENYLIST_ERROR,
    root: ALLOWED_DOMAIN_ERROR,
  },
  parsedMessage: {
    'email@example.com': DECODED_ALLOWED_DOMAIN_ERROR,
    'email4@example.com': DECODED_DOMAIN_DENYLIST_ERROR,
    'email5@example.com': DECODED_DOMAIN_DENYLIST_ERROR,
    root: DECODED_ALLOWED_DOMAIN_ERROR,
  },
  status: 'error',
};

const EMAIL_TAKEN = {
  message: {
    'email@example.org': "The member's email address has already been taken",
  },
  status: 'error',
};

const INVITE_LIMIT = {
  message: 'Invite limit of 5 per day exceeded.',
  status: 'error',
};

const ERROR_SEAT_LIMIT_REACHED = {
  message: 'No seats available',
  status: 'error',
  reason: 'seat_limit_exceeded_error',
};

export const GROUPS_INVITATIONS_PATH = '/api/v4/groups/1/invitations';

export const invitationsApiResponse = {
  EMAIL_INVALID,
  ERROR_EMAIL_INVALID,
  EMAIL_RESTRICTED,
  MULTIPLE_RESTRICTED,
  EMAIL_TAKEN,
  EXPANDED_RESTRICTED,
  INVITE_LIMIT,
  ERROR_SEAT_LIMIT_REACHED,
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
const SEAT_OVERAGE_IMPORT_ERRORS = {
  message: 'There are not enough available seats to invite this many users.',
  reason: 'seat_limit_exceeded_error',
};
export const importProjectMembersApiResponse = {
  EXPANDED_IMPORT_ERRORS,
  NO_COLLAPSE_IMPORT_ERRORS,
  SEAT_OVERAGE_IMPORT_ERRORS,
};
