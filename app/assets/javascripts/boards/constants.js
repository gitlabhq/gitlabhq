import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import { TYPE_EPIC, TYPE_ISSUE, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { s__, __ } from '~/locale';
import { TYPENAME_ISSUE } from '~/graphql_shared/constants';
import updateEpicSubscriptionMutation from '~/sidebar/queries/update_epic_subscription.mutation.graphql';
import updateEpicTitleMutation from '~/sidebar/queries/update_epic_title.mutation.graphql';
import createBoardListMutation from './graphql/board_list_create.mutation.graphql';
import destroyBoardListMutation from './graphql/board_list_destroy.mutation.graphql';
import updateBoardListMutation from './graphql/board_list_update.mutation.graphql';

import toggleListCollapsedMutation from './graphql/client/board_toggle_collapsed.mutation.graphql';
import issueSetSubscriptionMutation from './graphql/issue_set_subscription.mutation.graphql';
import issueSetTitleMutation from './graphql/issue_set_title.mutation.graphql';
import issueMoveListMutation from './graphql/issue_move_list.mutation.graphql';
import issueCreateMutation from './graphql/issue_create.mutation.graphql';
import groupBoardQuery from './graphql/group_board.query.graphql';
import projectBoardQuery from './graphql/project_board.query.graphql';
import listIssuesQuery from './graphql/lists_issues.query.graphql';
import listDeferredQuery from './graphql/board_lists_deferred.query.graphql';

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

export const INCIDENT = 'INCIDENT';

export const flashAnimationDuration = 2000;

export const boardQuery = {
  [WORKSPACE_GROUP]: {
    query: groupBoardQuery,
  },
  [WORKSPACE_PROJECT]: {
    query: projectBoardQuery,
  },
};

export const listsQuery = {
  [TYPE_ISSUE]: {
    query: boardListsQuery,
  },
};

export const listsDeferredQuery = {
  [TYPE_ISSUE]: {
    query: listDeferredQuery,
  },
};

export const createListMutations = {
  [TYPE_ISSUE]: {
    mutation: createBoardListMutation,
  },
};

export const updateListQueries = {
  [TYPE_ISSUE]: {
    mutation: updateBoardListMutation,
  },
};

export const toggleCollapsedMutations = {
  [TYPE_ISSUE]: {
    mutation: toggleListCollapsedMutation,
  },
};

export const deleteListQueries = {
  [TYPE_ISSUE]: {
    mutation: destroyBoardListMutation,
  },
};

export const titleQueries = {
  [TYPE_ISSUE]: {
    mutation: issueSetTitleMutation,
  },
  [TYPE_EPIC]: {
    mutation: updateEpicTitleMutation,
  },
};

export const subscriptionQueries = {
  [TYPE_ISSUE]: {
    mutation: issueSetSubscriptionMutation,
  },
  [TYPE_EPIC]: {
    mutation: updateEpicSubscriptionMutation,
  },
};

export const listIssuablesQueries = {
  [TYPE_ISSUE]: {
    query: listIssuesQuery,
    moveMutation: issueMoveListMutation,
    createMutation: issueCreateMutation,
    optimisticResponse: {
      assignees: { nodes: [], __typename: 'UserCoreConnection' },
      confidential: false,
      closedAt: null,
      dueDate: null,
      emailsEnabled: true,
      hidden: false,
      humanTimeEstimate: null,
      humanTotalTimeSpent: null,
      id: 'gid://gitlab/Issue/-1',
      iid: '-1',
      labels: { nodes: [], __typename: 'LabelConnection' },
      milestone: null,
      referencePath: '',
      relativePosition: null,
      severity: 'UNKNOWN',
      timeEstimate: 0,
      title: '',
      totalTimeSpent: 0,
      type: 'ISSUE',
      webUrl: '',
      weight: null,
      __typename: TYPENAME_ISSUE,
    },
  },
};

export const FilterFields = {
  [TYPE_ISSUE]: [
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
/* eslint-enable @gitlab/require-i18n-strings */

export const DraggableItemTypes = {
  card: 'card',
  list: 'list',
};

export const MilestoneIDs = {
  NONE: 0,
  ANY: -1,
};

export default {
  ListType,
};

export const DEFAULT_BOARD_LIST_ITEMS_SIZE = 10;

export const BOARD_CARD_MOVE_TO_POSITIONS_START_OPTION = s__('Boards|Move to start of list');
export const BOARD_CARD_MOVE_TO_POSITIONS_END_OPTION = s__('Boards|Move to end of list');

/**
 * Actions are stubbed in order to pass validation
 * for GlDisclosureDropdown items property
 */
export const BOARD_CARD_MOVE_TO_POSITIONS_OPTIONS = [
  {
    text: BOARD_CARD_MOVE_TO_POSITIONS_START_OPTION,
    action: () => {},
    extraAttrs: {
      role: 'button',
    },
  },
  {
    text: BOARD_CARD_MOVE_TO_POSITIONS_END_OPTION,
    action: () => {},
    extraAttrs: {
      role: 'button',
    },
  },
];

export const GroupByParamType = {};
