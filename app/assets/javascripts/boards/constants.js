import { __ } from '~/locale';

export const BoardType = {
  project: 'project',
  group: 'group',
};

export const ListType = {
  assignee: 'assignee',
  milestone: 'milestone',
  iteration: 'iteration',
  backlog: 'backlog',
  closed: 'closed',
  label: 'label',
};

export const ListTypeTitles = {
  assignee: __('Assignee'),
  milestone: __('Milestone'),
  iteration: __('Iteration'),
  label: __('Label'),
};

export const inactiveId = 0;

export const ISSUABLE = 'issuable';
export const LIST = 'list';

export const NOT_FILTER = 'not[';

export default {
  BoardType,
  ListType,
};
