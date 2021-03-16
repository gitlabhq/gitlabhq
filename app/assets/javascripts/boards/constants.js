import { __ } from '~/locale';
import boardBlockingIssuesQuery from './graphql/board_blocking_issues.query.graphql';

export const issuableTypes = {
  issue: 'issue',
  epic: 'epic',
};

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

export const formType = {
  new: 'new',
  delete: 'delete',
  edit: 'edit',
};

export const inactiveId = 0;

export const ISSUABLE = 'issuable';
export const LIST = 'list';

export const NOT_FILTER = 'not[';

export const flashAnimationDuration = 2000;

export default {
  BoardType,
  ListType,
};

export const blockingIssuablesQueries = {
  [issuableTypes.issue]: {
    query: boardBlockingIssuesQuery,
  },
};
