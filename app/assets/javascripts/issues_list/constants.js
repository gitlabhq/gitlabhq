import { __, s__ } from '~/locale';
import {
  FILTER_ANY,
  FILTER_CURRENT,
  FILTER_NONE,
  OPERATOR_IS,
  OPERATOR_IS_NOT,
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
  closed: __('CLOSED'),
  closedMoved: __('CLOSED (MOVED)'),
  confidentialNo: __('No'),
  confidentialYes: __('Yes'),
  downvotes: __('Downvotes'),
  editIssues: __('Edit issues'),
  errorFetchingIssues: __('An error occurred while loading issues'),
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
  relatedMergeRequests: __('Related merge requests'),
  reorderError: __('An error occurred while reordering issues.'),
  rssLabel: __('Subscribe to RSS feed'),
  searchPlaceholder: __('Search or filter results…'),
  upvotes: __('Upvotes'),
};

export const JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY = 'jira-import-success-alert-hide-map';

export const PARAM_DUE_DATE = 'due_date';
export const PARAM_PAGE = 'page';
export const PARAM_SORT = 'sort';
export const PARAM_STATE = 'state';

export const DUE_DATE_NONE = '0';
export const DUE_DATE_ANY = '';
export const DUE_DATE_OVERDUE = 'overdue';
export const DUE_DATE_WEEK = 'week';
export const DUE_DATE_MONTH = 'month';
export const DUE_DATE_NEXT_MONTH_AND_PREVIOUS_TWO_WEEKS = 'next_month_and_previous_two_weeks';
export const DUE_DATE_VALUES = [
  DUE_DATE_NONE,
  DUE_DATE_ANY,
  DUE_DATE_OVERDUE,
  DUE_DATE_WEEK,
  DUE_DATE_MONTH,
  DUE_DATE_NEXT_MONTH_AND_PREVIOUS_TWO_WEEKS,
];

export const BLOCKING_ISSUES_DESC = 'BLOCKING_ISSUES_DESC';
export const CREATED_ASC = 'CREATED_ASC';
export const CREATED_DESC = 'CREATED_DESC';
export const DUE_DATE_ASC = 'DUE_DATE_ASC';
export const DUE_DATE_DESC = 'DUE_DATE_DESC';
export const LABEL_PRIORITY_DESC = 'LABEL_PRIORITY_DESC';
export const MILESTONE_DUE_ASC = 'MILESTONE_DUE_ASC';
export const MILESTONE_DUE_DESC = 'MILESTONE_DUE_DESC';
export const POPULARITY_ASC = 'POPULARITY_ASC';
export const POPULARITY_DESC = 'POPULARITY_DESC';
export const PRIORITY_DESC = 'PRIORITY_DESC';
export const RELATIVE_POSITION_DESC = 'RELATIVE_POSITION_DESC';
export const UPDATED_ASC = 'UPDATED_ASC';
export const UPDATED_DESC = 'UPDATED_DESC';
export const WEIGHT_ASC = 'WEIGHT_ASC';
export const WEIGHT_DESC = 'WEIGHT_DESC';

const SORT_ASC = 'asc';
const SORT_DESC = 'desc';

const CREATED_DATE_SORT = 'created_date';
const CREATED_ASC_SORT = 'created_asc';
const UPDATED_DESC_SORT = 'updated_desc';
const UPDATED_ASC_SORT = 'updated_asc';
const MILESTONE_SORT = 'milestone';
const MILESTONE_DUE_DESC_SORT = 'milestone_due_desc';
const DUE_DATE_DESC_SORT = 'due_date_desc';
const POPULARITY_ASC_SORT = 'popularity_asc';
const WEIGHT_DESC_SORT = 'weight_desc';
const BLOCKING_ISSUES_DESC_SORT = 'blocking_issues_desc';
const BLOCKING_ISSUES = 'blocking_issues';

export const apiSortParams = {
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
  [LABEL_PRIORITY_DESC]: {
    order_by: LABEL_PRIORITY,
    sort: SORT_DESC,
  },
  [RELATIVE_POSITION_DESC]: {
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
  [BLOCKING_ISSUES_DESC]: {
    order_by: BLOCKING_ISSUES,
    sort: SORT_DESC,
  },
};

export const urlSortParams = {
  [PRIORITY_DESC]: {
    sort: PRIORITY,
  },
  [CREATED_ASC]: {
    sort: CREATED_ASC_SORT,
  },
  [CREATED_DESC]: {
    sort: CREATED_DATE_SORT,
  },
  [UPDATED_ASC]: {
    sort: UPDATED_ASC_SORT,
  },
  [UPDATED_DESC]: {
    sort: UPDATED_DESC_SORT,
  },
  [MILESTONE_DUE_ASC]: {
    sort: MILESTONE_SORT,
  },
  [MILESTONE_DUE_DESC]: {
    sort: MILESTONE_DUE_DESC_SORT,
  },
  [DUE_DATE_ASC]: {
    sort: DUE_DATE,
  },
  [DUE_DATE_DESC]: {
    sort: DUE_DATE_DESC_SORT,
  },
  [POPULARITY_ASC]: {
    sort: POPULARITY_ASC_SORT,
  },
  [POPULARITY_DESC]: {
    sort: POPULARITY,
  },
  [LABEL_PRIORITY_DESC]: {
    sort: LABEL_PRIORITY,
  },
  [RELATIVE_POSITION_DESC]: {
    sort: RELATIVE_POSITION,
    per_page: 100,
  },
  [WEIGHT_ASC]: {
    sort: WEIGHT,
  },
  [WEIGHT_DESC]: {
    sort: WEIGHT_DESC_SORT,
  },
  [BLOCKING_ISSUES_DESC]: {
    sort: BLOCKING_ISSUES_DESC_SORT,
  },
};

export const MAX_LIST_SIZE = 10;

export const API_PARAM = 'apiParam';
export const URL_PARAM = 'urlParam';
export const NORMAL_FILTER = 'normalFilter';
export const SPECIAL_FILTER = 'specialFilter';
export const ALTERNATIVE_FILTER = 'alternativeFilter';
export const SPECIAL_FILTER_VALUES = [FILTER_NONE, FILTER_ANY, FILTER_CURRENT];

export const filters = {
  author_username: {
    [API_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'author_username',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[author_username]',
      },
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'author_username',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[author_username]',
      },
    },
  },
  assignee_username: {
    [API_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'assignee_username',
        [SPECIAL_FILTER]: 'assignee_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[assignee_username]',
      },
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'assignee_username[]',
        [SPECIAL_FILTER]: 'assignee_id',
        [ALTERNATIVE_FILTER]: 'assignee_username',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[assignee_username][]',
      },
    },
  },
  milestone: {
    [API_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'milestone',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[milestone]',
      },
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'milestone_title',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[milestone_title]',
      },
    },
  },
  labels: {
    [API_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'labels',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[labels]',
      },
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'label_name[]',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[label_name][]',
      },
    },
  },
  my_reaction_emoji: {
    [API_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'my_reaction_emoji',
        [SPECIAL_FILTER]: 'my_reaction_emoji',
      },
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'my_reaction_emoji',
        [SPECIAL_FILTER]: 'my_reaction_emoji',
      },
    },
  },
  confidential: {
    [API_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'confidential',
      },
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'confidential',
      },
    },
  },
  iteration: {
    [API_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'iteration_title',
        [SPECIAL_FILTER]: 'iteration_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[iteration_title]',
      },
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'iteration_title',
        [SPECIAL_FILTER]: 'iteration_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[iteration_title]',
      },
    },
  },
  epic_id: {
    [API_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'epic_id',
        [SPECIAL_FILTER]: 'epic_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[epic_id]',
      },
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'epic_id',
        [SPECIAL_FILTER]: 'epic_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[epic_id]',
      },
    },
  },
  weight: {
    [API_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'weight',
        [SPECIAL_FILTER]: 'weight',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[weight]',
      },
    },
    [URL_PARAM]: {
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
