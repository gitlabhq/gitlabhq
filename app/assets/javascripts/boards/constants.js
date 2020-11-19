export const BoardType = {
  project: 'project',
  group: 'group',
};

export const ListType = {
  assignee: 'assignee',
  milestone: 'milestone',
  backlog: 'backlog',
  closed: 'closed',
  label: 'label',
  promotion: 'promotion',
  blank: 'blank',
};

export const inactiveId = 0;

export const ISSUABLE = 'issuable';
export const LIST = 'list';

/* eslint-disable-next-line @gitlab/require-i18n-strings */
export const DEFAULT_LABELS = ['to do', 'doing'];

export default {
  BoardType,
  ListType,
  DEFAULT_LABELS,
};
