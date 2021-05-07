import { __, s__ } from '~/locale';
import {
  FILTER_ANY,
  FILTER_CURRENT,
  FILTER_NONE,
} from '~/vue_shared/components/filtered_search_bar/constants';

// Maps sort order as it appears in the URL query to API `order_by` and `sort` params.
const PRIORITY = 'priority';
const ASC = 'asc';
const DESC = 'desc';
const CREATED_AT = 'created_at';
const UPDATED_AT = 'updated_at';
const DUE_DATE = 'due_date';
const MILESTONE_DUE = 'milestone_due';
const POPULARITY = 'popularity';
const WEIGHT = 'weight';
const LABEL_PRIORITY = 'label_priority';
export const RELATIVE_POSITION = 'relative_position';
export const LOADING_LIST_ITEMS_LENGTH = 8;
export const PAGE_SIZE = 20;
export const PAGE_SIZE_MANUAL = 100;

export const sortOrderMap = {
  priority: { order_by: PRIORITY, sort: ASC }, // asc and desc are flipped for some reason
  created_date: { order_by: CREATED_AT, sort: DESC },
  created_asc: { order_by: CREATED_AT, sort: ASC },
  updated_desc: { order_by: UPDATED_AT, sort: DESC },
  updated_asc: { order_by: UPDATED_AT, sort: ASC },
  milestone_due_desc: { order_by: MILESTONE_DUE, sort: DESC },
  milestone: { order_by: MILESTONE_DUE, sort: ASC },
  due_date_desc: { order_by: DUE_DATE, sort: DESC },
  due_date: { order_by: DUE_DATE, sort: ASC },
  popularity: { order_by: POPULARITY, sort: DESC },
  popularity_asc: { order_by: POPULARITY, sort: ASC },
  label_priority: { order_by: LABEL_PRIORITY, sort: ASC }, // asc and desc are flipped
  relative_position: { order_by: RELATIVE_POSITION, sort: ASC },
  weight_desc: { order_by: WEIGHT, sort: DESC },
  weight: { order_by: WEIGHT, sort: ASC },
};

export const availableSortOptionsJira = [
  {
    id: 1,
    title: __('Created date'),
    sortDirection: {
      descending: 'created_desc',
      ascending: 'created_asc',
    },
  },
  {
    id: 2,
    title: __('Last updated'),
    sortDirection: {
      descending: 'updated_desc',
      ascending: 'updated_asc',
    },
  },
];

export const i18n = {
  calendarLabel: __('Subscribe to calendar'),
  jiraIntegrationMessage: s__(
    'JiraService|%{jiraDocsLinkStart}Enable the Jira integration%{jiraDocsLinkEnd} to view your Jira issues in GitLab.',
  ),
  jiraIntegrationSecondaryMessage: s__('JiraService|This feature requires a Premium plan.'),
  jiraIntegrationTitle: s__('JiraService|Using Jira for issue tracking?'),
  newIssueLabel: __('New issue'),
  noClosedIssuesTitle: __('There are no closed issues'),
  noOpenIssuesDescription: __('To keep this project going, create a new issue'),
  noOpenIssuesTitle: __('There are no open issues'),
  noIssuesSignedInDescription: __(
    'Issues can be bugs, tasks or ideas to be discussed. Also, issues are searchable and filterable.',
  ),
  noIssuesSignedInTitle: __(
    'The Issue Tracker is the place to add things that need to be improved or solved in a project',
  ),
  noIssuesSignedOutButtonText: __('Register / Sign In'),
  noIssuesSignedOutDescription: __(
    'The Issue Tracker is the place to add things that need to be improved or solved in a project. You can register or sign in to create issues for this project.',
  ),
  noIssuesSignedOutTitle: __('There are no issues to show'),
  noSearchResultsDescription: __('To widen your search, change or remove filters above'),
  noSearchResultsTitle: __('Sorry, your filter produced no results'),
  reorderError: __('An error occurred while reordering issues.'),
  rssLabel: __('Subscribe to RSS feed'),
};

export const JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY = 'jira-import-success-alert-hide-map';

export const BLOCKING_ISSUES_ASC = 'BLOCKING_ISSUES_ASC';
export const BLOCKING_ISSUES_DESC = 'BLOCKING_ISSUES_DESC';
export const CREATED_ASC = 'CREATED_ASC';
export const CREATED_DESC = 'CREATED_DESC';
export const DUE_DATE_ASC = 'DUE_DATE_ASC';
export const DUE_DATE_DESC = 'DUE_DATE_DESC';
export const LABEL_PRIORITY_ASC = 'LABEL_PRIORITY_ASC';
export const LABEL_PRIORITY_DESC = 'LABEL_PRIORITY_DESC';
export const MILESTONE_DUE_ASC = 'MILESTONE_DUE_ASC';
export const MILESTONE_DUE_DESC = 'MILESTONE_DUE_DESC';
export const POPULARITY_ASC = 'POPULARITY_ASC';
export const POPULARITY_DESC = 'POPULARITY_DESC';
export const PRIORITY_ASC = 'PRIORITY_ASC';
export const PRIORITY_DESC = 'PRIORITY_DESC';
export const RELATIVE_POSITION_ASC = 'RELATIVE_POSITION_ASC';
export const UPDATED_ASC = 'UPDATED_ASC';
export const UPDATED_DESC = 'UPDATED_DESC';
export const WEIGHT_ASC = 'WEIGHT_ASC';
export const WEIGHT_DESC = 'WEIGHT_DESC';

const SORT_ASC = 'asc';
const SORT_DESC = 'desc';

const BLOCKING_ISSUES = 'blocking_issues';

export const sortParams = {
  [PRIORITY_ASC]: {
    order_by: PRIORITY,
    sort: SORT_ASC,
  },
  [PRIORITY_DESC]: {
    order_by: PRIORITY,
    sort: SORT_DESC,
  },
  [CREATED_ASC]: {
    order_by: CREATED_AT,
    sort: SORT_ASC,
  },
  [CREATED_DESC]: {
    order_by: CREATED_AT,
    sort: SORT_DESC,
  },
  [UPDATED_ASC]: {
    order_by: UPDATED_AT,
    sort: SORT_ASC,
  },
  [UPDATED_DESC]: {
    order_by: UPDATED_AT,
    sort: SORT_DESC,
  },
  [MILESTONE_DUE_ASC]: {
    order_by: MILESTONE_DUE,
    sort: SORT_ASC,
  },
  [MILESTONE_DUE_DESC]: {
    order_by: MILESTONE_DUE,
    sort: SORT_DESC,
  },
  [DUE_DATE_ASC]: {
    order_by: DUE_DATE,
    sort: SORT_ASC,
  },
  [DUE_DATE_DESC]: {
    order_by: DUE_DATE,
    sort: SORT_DESC,
  },
  [POPULARITY_ASC]: {
    order_by: POPULARITY,
    sort: SORT_ASC,
  },
  [POPULARITY_DESC]: {
    order_by: POPULARITY,
    sort: SORT_DESC,
  },
  [LABEL_PRIORITY_ASC]: {
    order_by: LABEL_PRIORITY,
    sort: SORT_ASC,
  },
  [LABEL_PRIORITY_DESC]: {
    order_by: LABEL_PRIORITY,
    sort: SORT_DESC,
  },
  [RELATIVE_POSITION_ASC]: {
    order_by: RELATIVE_POSITION,
    per_page: 100,
    sort: SORT_ASC,
  },
  [WEIGHT_ASC]: {
    order_by: WEIGHT,
    sort: SORT_ASC,
  },
  [WEIGHT_DESC]: {
    order_by: WEIGHT,
    sort: SORT_DESC,
  },
  [BLOCKING_ISSUES_ASC]: {
    order_by: BLOCKING_ISSUES,
    sort: SORT_ASC,
  },
  [BLOCKING_ISSUES_DESC]: {
    order_by: BLOCKING_ISSUES,
    sort: SORT_DESC,
  },
};

export const MAX_LIST_SIZE = 10;

export const FILTERED_SEARCH_TERM = 'filtered-search-term';
export const OPERATOR_IS = '=';
export const OPERATOR_IS_NOT = '!=';

export const NORMAL_FILTER = 'normalFilter';
export const SPECIAL_FILTER = 'specialFilter';
export const SPECIAL_FILTER_VALUES = [FILTER_NONE, FILTER_ANY, FILTER_CURRENT];

export const filters = {
  author_username: {
    apiParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'author_username',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[author_username]',
      },
    },
    urlParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'author_username',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[author_username]',
      },
    },
  },
  assignee_username: {
    apiParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'assignee_username',
        [SPECIAL_FILTER]: 'assignee_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[assignee_username]',
      },
    },
    urlParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'assignee_username[]',
        [SPECIAL_FILTER]: 'assignee_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[assignee_username][]',
      },
    },
  },
  milestone: {
    apiParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'milestone',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[milestone]',
      },
    },
    urlParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'milestone_title',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[milestone_title]',
      },
    },
  },
  labels: {
    apiParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'labels',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[labels]',
      },
    },
    urlParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'label_name[]',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[label_name][]',
      },
    },
  },
  my_reaction_emoji: {
    apiParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'my_reaction_emoji',
        [SPECIAL_FILTER]: 'my_reaction_emoji',
      },
    },
    urlParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'my_reaction_emoji',
        [SPECIAL_FILTER]: 'my_reaction_emoji',
      },
    },
  },
  confidential: {
    apiParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'confidential',
      },
    },
    urlParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'confidential',
      },
    },
  },
  iteration: {
    apiParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'iteration_title',
        [SPECIAL_FILTER]: 'iteration_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[iteration_title]',
      },
    },
    urlParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'iteration_title',
        [SPECIAL_FILTER]: 'iteration_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[iteration_title]',
      },
    },
  },
  weight: {
    apiParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'weight',
        [SPECIAL_FILTER]: 'weight',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[weight]',
      },
    },
    urlParam: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'weight',
        [SPECIAL_FILTER]: 'weight',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[weight]',
      },
    },
  },
};
