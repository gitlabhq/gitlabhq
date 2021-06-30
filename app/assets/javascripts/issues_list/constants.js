import getIssuesCountQuery from 'ee_else_ce/issues_list/queries/get_issues_count.query.graphql';
import createFlash from '~/flash';
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
  errorFetchingCounts: __('An error occurred while getting issue counts'),
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
export const PARAM_SORT = 'sort';
export const PARAM_STATE = 'state';

export const initialPageParams = {
  firstPageSize: PAGE_SIZE,
};

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

const PRIORITY_ASC_SORT = 'priority_asc';
const CREATED_DATE_SORT = 'created_date';
const CREATED_ASC_SORT = 'created_asc';
const UPDATED_DESC_SORT = 'updated_desc';
const UPDATED_ASC_SORT = 'updated_asc';
const MILESTONE_SORT = 'milestone';
const MILESTONE_DUE_DESC_SORT = 'milestone_due_desc';
const DUE_DATE_DESC_SORT = 'due_date_desc';
const LABEL_PRIORITY_ASC_SORT = 'label_priority_asc';
const POPULARITY_ASC_SORT = 'popularity_asc';
const WEIGHT_DESC_SORT = 'weight_desc';
const BLOCKING_ISSUES_DESC_SORT = 'blocking_issues_desc';

export const urlSortParams = {
  [PRIORITY_ASC]: PRIORITY_ASC_SORT,
  [PRIORITY_DESC]: PRIORITY,
  [CREATED_ASC]: CREATED_ASC_SORT,
  [CREATED_DESC]: CREATED_DATE_SORT,
  [UPDATED_ASC]: UPDATED_ASC_SORT,
  [UPDATED_DESC]: UPDATED_DESC_SORT,
  [MILESTONE_DUE_ASC]: MILESTONE_SORT,
  [MILESTONE_DUE_DESC]: MILESTONE_DUE_DESC_SORT,
  [DUE_DATE_ASC]: DUE_DATE,
  [DUE_DATE_DESC]: DUE_DATE_DESC_SORT,
  [POPULARITY_ASC]: POPULARITY_ASC_SORT,
  [POPULARITY_DESC]: POPULARITY,
  [LABEL_PRIORITY_ASC]: LABEL_PRIORITY_ASC_SORT,
  [LABEL_PRIORITY_DESC]: LABEL_PRIORITY,
  [RELATIVE_POSITION_ASC]: RELATIVE_POSITION,
  [WEIGHT_ASC]: WEIGHT,
  [WEIGHT_DESC]: WEIGHT_DESC_SORT,
  [BLOCKING_ISSUES_DESC]: BLOCKING_ISSUES_DESC_SORT,
};

export const MAX_LIST_SIZE = 10;

export const API_PARAM = 'apiParam';
export const URL_PARAM = 'urlParam';
export const NORMAL_FILTER = 'normalFilter';
export const SPECIAL_FILTER = 'specialFilter';
export const ALTERNATIVE_FILTER = 'alternativeFilter';
export const SPECIAL_FILTER_VALUES = [FILTER_NONE, FILTER_ANY, FILTER_CURRENT];

export const TOKEN_TYPE_AUTHOR = 'author_username';
export const TOKEN_TYPE_ASSIGNEE = 'assignee_username';
export const TOKEN_TYPE_MILESTONE = 'milestone';
export const TOKEN_TYPE_LABEL = 'labels';
export const TOKEN_TYPE_MY_REACTION = 'my_reaction_emoji';
export const TOKEN_TYPE_CONFIDENTIAL = 'confidential';
export const TOKEN_TYPE_ITERATION = 'iteration';
export const TOKEN_TYPE_EPIC = 'epic_id';
export const TOKEN_TYPE_WEIGHT = 'weight';

export const filters = {
  [TOKEN_TYPE_AUTHOR]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'authorUsername',
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
  [TOKEN_TYPE_ASSIGNEE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'assigneeUsernames',
      [SPECIAL_FILTER]: 'assigneeId',
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
  [TOKEN_TYPE_MILESTONE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'milestoneTitle',
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
  [TOKEN_TYPE_LABEL]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'labelName',
      [SPECIAL_FILTER]: 'labelName',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'label_name[]',
        [SPECIAL_FILTER]: 'label_name[]',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[label_name][]',
      },
    },
  },
  [TOKEN_TYPE_MY_REACTION]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'myReactionEmoji',
      [SPECIAL_FILTER]: 'myReactionEmoji',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'my_reaction_emoji',
        [SPECIAL_FILTER]: 'my_reaction_emoji',
      },
    },
  },
  [TOKEN_TYPE_CONFIDENTIAL]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'confidential',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'confidential',
      },
    },
  },
  [TOKEN_TYPE_ITERATION]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'iterationId',
      [SPECIAL_FILTER]: 'iterationWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'iteration_id',
        [SPECIAL_FILTER]: 'iteration_id',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[iteration_id]',
      },
    },
  },
  [TOKEN_TYPE_EPIC]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'epicId',
      [SPECIAL_FILTER]: 'epicId',
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
  [TOKEN_TYPE_WEIGHT]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'weight',
      [SPECIAL_FILTER]: 'weight',
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

export const issuesCountSmartQueryBase = {
  query: getIssuesCountQuery,
  context: {
    isSingleRequest: true,
  },
  update: ({ project }) => project?.issues.count,
  error(error) {
    createFlash({ message: i18n.errorFetchingCounts, captureError: true, error });
  },
  debounce: 200,
};
