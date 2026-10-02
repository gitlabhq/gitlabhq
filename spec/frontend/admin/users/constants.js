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
const TRUST = 'trust';
const UNTRUST = 'untrust';
const RESYNC_LDAP = 'resyncLdap';

export const EDIT = 'edit';

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
  TRUST,
  UNTRUST,
  RESYNC_LDAP,
];

export const DELETE_ACTIONS = [DELETE, DELETE_WITH_CONTRIBUTIONS];
