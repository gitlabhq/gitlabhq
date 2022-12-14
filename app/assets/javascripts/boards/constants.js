import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import { __ } from '~/locale';
import updateEpicSubscriptionMutation from '~/sidebar/queries/update_epic_subscription.mutation.graphql';
import updateEpicTitleMutation from '~/sidebar/queries/update_epic_title.mutation.graphql';
import destroyBoardListMutation from './graphql/board_list_destroy.mutation.graphql';
import updateBoardListMutation from './graphql/board_list_update.mutation.graphql';

import issueSetSubscriptionMutation from './graphql/issue_set_subscription.mutation.graphql';
import issueSetTitleMutation from './graphql/issue_set_title.mutation.graphql';

/* eslint-disable-next-line @gitlab/require-i18n-strings */
export const AssigneeIdParamValues = ['Any', 'None'];

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
  backlog: __('Open'),
};

export const formType = {
  new: 'new',
  delete: 'delete',
  edit: 'edit',
};

export const toggleFormEventPrefix = {
  epic: 'toggle-epic-form-',
  issue: 'toggle-issue-form-',
};

export const active = 'active';

export const inactiveId = 0;

export const ISSUABLE = 'issuable';
export const LIST = 'list';
export const INCIDENT = 'INCIDENT';

export const flashAnimationDuration = 2000;

export const listsQuery = {
  [issuableTypes.issue]: {
    query: boardListsQuery,
  },
};

export const updateListQueries = {
  [issuableTypes.issue]: {
    mutation: updateBoardListMutation,
  },
};

export const deleteListQueries = {
  [issuableTypes.issue]: {
    mutation: destroyBoardListMutation,
  },
};

export const titleQueries = {
  [issuableTypes.issue]: {
    mutation: issueSetTitleMutation,
  },
  [issuableTypes.epic]: {
    mutation: updateEpicTitleMutation,
  },
};

export const subscriptionQueries = {
  [issuableTypes.issue]: {
    mutation: issueSetSubscriptionMutation,
  },
  [issuableTypes.epic]: {
    mutation: updateEpicSubscriptionMutation,
  },
};

export const FilterFields = {
  [issuableTypes.issue]: [
    'assigneeUsername',
    'assigneeWildcardId',
    'authorUsername',
    'confidential',
    'labelName',
    'milestoneTitle',
    'milestoneWildcardId',
    'myReactionEmoji',
    'releaseTag',
    'search',
    'types',
    'weight',
  ],
};

/* eslint-disable @gitlab/require-i18n-strings */
export const AssigneeFilterType = {
  any: 'Any',
  none: 'None',
};

export const MilestoneFilterType = {
  any: 'Any',
  none: 'None',
  started: 'Started',
  upcoming: 'Upcoming',
};

export const DraggableItemTypes = {
  card: 'card',
  list: 'list',
};

export const MilestoneIDs = {
  NONE: 0,
  ANY: -1,
};

export default {
  BoardType,
  ListType,
};

export const DEFAULT_BOARD_LIST_ITEMS_SIZE = 10;
