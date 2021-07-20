const BLOCK = 'block';
const UNBLOCK = 'unblock';
const DELETE = 'delete';
const DELETE_WITH_CONTRIBUTIONS = 'deleteWithContributions';
const UNLOCK = 'unlock';
const ACTIVATE = 'activate';
const DEACTIVATE = 'deactivate';
const REJECT = 'reject';
const APPROVE = 'approve';
const BAN = 'ban';
const UNBAN = 'unban';

export const EDIT = 'edit';

export const LDAP = 'ldapBlocked';

export const CONFIRMATION_ACTIONS = [
  ACTIVATE,
  BLOCK,
  DEACTIVATE,
  UNLOCK,
  UNBLOCK,
  BAN,
  UNBAN,
  APPROVE,
  REJECT,
];

export const DELETE_ACTIONS = [DELETE, DELETE_WITH_CONTRIBUTIONS];
