import { __, s__ } from '~/locale';
import {
  FILTER_ANY,
  FILTER_CURRENT,
  FILTER_NONE,
  FILTER_STARTED,
  FILTER_UPCOMING,
  OPERATOR_IS,
  OPERATOR_IS_NOT,
} from '~/vue_shared/components/filtered_search_bar/constants';

export const i18n = {
  anonymousSearchingMessage: __('You must sign in to search for specific terms.'),
  calendarLabel: __('Subscribe to calendar'),
  closed: __('CLOSED'),
  closedMoved: __('CLOSED (MOVED)'),
  confidentialNo: __('No'),
  confidentialYes: __('Yes'),
  downvotes: __('Downvotes'),
  editIssues: __('Edit issues'),
  errorFetchingCounts: __('An error occurred while getting issue counts'),
  errorFetchingIssues: __('An error occurred while loading issues'),
  issueRepositioningMessage: __(
    'Issues are being rebalanced at the moment, so manual reordering is disabled.',
  ),
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
  searchPlaceholder: __('Search or filter results...'),
  upvotes: __('Upvotes'),
};

export const ISSUE_REFERENCE = /^#\d+$/;
export const MAX_LIST_SIZE = 10;
export const PAGE_SIZE = 20;
export const PAGE_SIZE_MANUAL = 100;
export const PARAM_ASSIGNEE_ID = 'assignee_id';
export const PARAM_PAGE_AFTER = 'page_after';
export const PARAM_PAGE_BEFORE = 'page_before';
export const PARAM_STATE = 'state';
export const RELATIVE_POSITION = 'relative_position';

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
export const TITLE_ASC = 'TITLE_ASC';
export const TITLE_DESC = 'TITLE_DESC';
export const UPDATED_ASC = 'UPDATED_ASC';
export const UPDATED_DESC = 'UPDATED_DESC';
export const WEIGHT_ASC = 'WEIGHT_ASC';
export const WEIGHT_DESC = 'WEIGHT_DESC';

export const urlSortParams = {
  [PRIORITY_ASC]: 'priority',
  [PRIORITY_DESC]: 'priority_desc',
  [CREATED_ASC]: 'created_asc',
  [CREATED_DESC]: 'created_date',
  [UPDATED_ASC]: 'updated_asc',
  [UPDATED_DESC]: 'updated_desc',
  [MILESTONE_DUE_ASC]: 'milestone',
  [MILESTONE_DUE_DESC]: 'milestone_due_desc',
  [DUE_DATE_ASC]: 'due_date',
  [DUE_DATE_DESC]: 'due_date_desc',
  [POPULARITY_ASC]: 'popularity_asc',
  [POPULARITY_DESC]: 'popularity',
  [LABEL_PRIORITY_ASC]: 'label_priority',
  [LABEL_PRIORITY_DESC]: 'label_priority_desc',
  [RELATIVE_POSITION_ASC]: RELATIVE_POSITION,
  [WEIGHT_ASC]: 'weight',
  [WEIGHT_DESC]: 'weight_desc',
  [BLOCKING_ISSUES_ASC]: 'blocking_issues_asc',
  [BLOCKING_ISSUES_DESC]: 'blocking_issues_desc',
  [TITLE_ASC]: 'title_asc',
  [TITLE_DESC]: 'title_desc',
};

export const API_PARAM = 'apiParam';
export const URL_PARAM = 'urlParam';
export const NORMAL_FILTER = 'normalFilter';
export const SPECIAL_FILTER = 'specialFilter';
export const ALTERNATIVE_FILTER = 'alternativeFilter';

export const specialFilterValues = [
  FILTER_NONE,
  FILTER_ANY,
  FILTER_CURRENT,
  FILTER_UPCOMING,
  FILTER_STARTED,
];

export const TOKEN_TYPE_AUTHOR = 'author_username';
export const TOKEN_TYPE_ASSIGNEE = 'assignee_username';
export const TOKEN_TYPE_MILESTONE = 'milestone';
export const TOKEN_TYPE_LABEL = 'labels';
export const TOKEN_TYPE_TYPE = 'type';
export const TOKEN_TYPE_RELEASE = 'release';
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
      [SPECIAL_FILTER]: 'milestoneWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'milestone_title',
        [SPECIAL_FILTER]: 'milestone_title',
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
        [ALTERNATIVE_FILTER]: 'label_name',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[label_name][]',
      },
    },
  },
  [TOKEN_TYPE_TYPE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'types',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'type[]',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[type][]',
      },
    },
  },
  [TOKEN_TYPE_RELEASE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'releaseTag',
      [SPECIAL_FILTER]: 'releaseTagWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'release_tag',
        [SPECIAL_FILTER]: 'release_tag',
      },
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[release_tag]',
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
      [OPERATOR_IS_NOT]: {
        [NORMAL_FILTER]: 'not[my_reaction_emoji]',
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
