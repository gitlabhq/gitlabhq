import { __, s__ } from '~/locale';
import {
  FILTER_ANY,
  FILTER_CURRENT,
  FILTER_NONE,
  FILTER_STARTED,
  FILTER_UPCOMING,
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
  OPERATOR_NOT,
  OPERATOR_OR,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_CONTACT,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_ORGANIZATION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_WEIGHT,
  TOKEN_TYPE_SEARCH_WITHIN,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_TEST_CASE,
  WORK_ITEM_TYPE_ENUM_TASK,
} from '~/work_items/constants';

export const ISSUE_REFERENCE = /^#\d+$/;
export const MAX_LIST_SIZE = 10;
export const PARAM_ASSIGNEE_ID = 'assignee_id';
export const PARAM_FIRST_PAGE_SIZE = 'first_page_size';
export const PARAM_LAST_PAGE_SIZE = 'last_page_size';
export const PARAM_PAGE_AFTER = 'page_after';
export const PARAM_PAGE_BEFORE = 'page_before';
export const PARAM_SORT = 'sort';
export const PARAM_STATE = 'state';
export const RELATIVE_POSITION = 'relative_position';

export const BLOCKING_ISSUES_ASC = 'BLOCKING_ISSUES_ASC';
export const BLOCKING_ISSUES_DESC = 'BLOCKING_ISSUES_DESC';
export const CLOSED_AT_ASC = 'CLOSED_AT_ASC';
export const CLOSED_AT_DESC = 'CLOSED_AT_DESC';
export const CREATED_ASC = 'CREATED_ASC';
export const CREATED_DESC = 'CREATED_DESC';
export const DUE_DATE_ASC = 'DUE_DATE_ASC';
export const DUE_DATE_DESC = 'DUE_DATE_DESC';
export const HEALTH_STATUS_ASC = 'HEALTH_STATUS_ASC';
export const HEALTH_STATUS_DESC = 'HEALTH_STATUS_DESC';
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

export const API_PARAM = 'apiParam';
export const URL_PARAM = 'urlParam';
export const NORMAL_FILTER = 'normalFilter';
export const SPECIAL_FILTER = 'specialFilter';
export const ALTERNATIVE_FILTER = 'alternativeFilter';

export const i18n = {
  actionsLabel: __('Actions'),
  calendarLabel: __('Subscribe to calendar'),
  closed: __('Closed'),
  closedMoved: __('Closed (moved)'),
  confidentialNo: __('No'),
  confidentialYes: __('Yes'),
  downvotes: __('Downvotes'),
  editIssues: __('Bulk edit'),
  errorFetchingCounts: __('An error occurred while getting issue counts'),
  errorFetchingIssues: __('An error occurred while loading issues'),
  importIssues: __('Import issues'),
  issueRepositioningMessage: __(
    'Issues are being rebalanced at the moment, so manual reordering is disabled.',
  ),
  jiraIntegrationMessage: s__(
    'JiraService|%{jiraDocsLinkStart}Enable the Jira integration%{jiraDocsLinkEnd} to view your Jira issues in GitLab.',
  ),
  jiraIntegrationSecondaryMessage: s__('JiraService|This feature requires a Premium plan.'),
  jiraIntegrationTitle: s__('JiraService|Using Jira for issue tracking?'),
  newIssueLabel: __('New issue'),
  newProjectLabel: __('New project'),
  noClosedIssuesTitle: __('There are no closed issues'),
  noGroupIssuesSignedInDescription: __(
    'Issues exist in projects, so to create an issue, first create a project.',
  ),
  noOpenIssuesDescription: __('To keep this project going, create a new issue'),
  noOpenIssuesTitle: __('There are no open issues'),
  noIssuesDescription: __('Learn more about issues.'),
  noIssuesTitle: __('Use issues to collaborate on ideas, solve problems, and plan work'),
  noIssuesSignedOutButtonText: __('Register / Sign In'),
  noSearchNoFilterTitle: __('Please select at least one filter to see results'),
  noSearchResultsDescription: __('To widen your search, change or remove filters above'),
  noSearchResultsTitle: __('Sorry, your filter produced no results'),
  relatedMergeRequests: __('Related merge requests'),
  reorderError: __('An error occurred while reordering issues.'),
  rssLabel: __('Subscribe to RSS feed'),
  searchPlaceholder: __('Search or filter results...'),
  upvotes: __('Upvotes'),
  titles: __('Titles'),
  descriptions: __('Descriptions'),
};

export const urlSortParams = {
  [PRIORITY_ASC]: 'priority',
  [PRIORITY_DESC]: 'priority_desc',
  [CREATED_ASC]: 'created_asc',
  [CREATED_DESC]: 'created_date',
  [UPDATED_ASC]: 'updated_asc',
  [UPDATED_DESC]: 'updated_desc',
  [CLOSED_AT_ASC]: 'closed_at',
  [CLOSED_AT_DESC]: 'closed_at_desc',
  [MILESTONE_DUE_ASC]: 'milestone',
  [MILESTONE_DUE_DESC]: 'milestone_due_desc',
  [DUE_DATE_ASC]: 'due_date',
  [DUE_DATE_DESC]: 'due_date_desc',
  [POPULARITY_ASC]: 'popularity_asc',
  [POPULARITY_DESC]: 'popularity',
  [LABEL_PRIORITY_ASC]: 'label_priority',
  [LABEL_PRIORITY_DESC]: 'label_priority_desc',
  [RELATIVE_POSITION_ASC]: RELATIVE_POSITION,
  [TITLE_ASC]: 'title_asc',
  [TITLE_DESC]: 'title_desc',
  [HEALTH_STATUS_ASC]: 'health_status_asc',
  [HEALTH_STATUS_DESC]: 'health_status_desc',
  [WEIGHT_ASC]: 'weight',
  [WEIGHT_DESC]: 'weight_desc',
  [BLOCKING_ISSUES_ASC]: 'blocking_issues_asc',
  [BLOCKING_ISSUES_DESC]: 'blocking_issues_desc',
};

export const specialFilterValues = [
  FILTER_NONE,
  FILTER_ANY,
  FILTER_CURRENT,
  FILTER_UPCOMING,
  FILTER_STARTED,
];

export const TYPE_TOKEN_OBJECTIVE_OPTION = {
  icon: 'issue-type-objective',
  title: s__('WorkItem|Objective'),
  value: 'objective',
};

export const TYPE_TOKEN_KEY_RESULT_OPTION = {
  icon: 'issue-type-keyresult',
  title: s__('WorkItem|Key Result'),
  value: 'key_result',
};

// This should be consistent with Issue::TYPES_FOR_LIST in the backend
// https://gitlab.com/gitlab-org/gitlab/-/blob/1379c2d7bffe2a8d809f23ac5ef9b4114f789c07/app/models/issue.rb#L48
export const defaultWorkItemTypes = [
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_TEST_CASE,
  WORK_ITEM_TYPE_ENUM_TASK,
];

export const defaultTypeTokenOptions = [
  { icon: 'issue-type-issue', title: s__('WorkItem|Issue'), value: 'issue' },
  { icon: 'issue-type-incident', title: s__('WorkItem|Incident'), value: 'incident' },
  { icon: 'issue-type-test-case', title: s__('WorkItem|Test case'), value: 'test_case' },
  { icon: 'issue-type-task', title: s__('WorkItem|Task'), value: 'task' },
];

export const filtersMap = {
  [FILTERED_SEARCH_TERM]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'search',
    },
    [URL_PARAM]: {
      [undefined]: {
        [NORMAL_FILTER]: 'search',
      },
    },
  },
  [TOKEN_TYPE_AUTHOR]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'authorUsername',
      [ALTERNATIVE_FILTER]: 'authorUsernames',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'author_username',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[author_username]',
      },
      [OPERATOR_OR]: {
        [ALTERNATIVE_FILTER]: 'or[author_username]',
      },
    },
  },
  [TOKEN_TYPE_SEARCH_WITHIN]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'in',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'in',
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
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[assignee_username][]',
      },
      [OPERATOR_OR]: {
        [NORMAL_FILTER]: 'or[assignee_username][]',
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
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[milestone_title]',
        [SPECIAL_FILTER]: 'not[milestone_title]',
      },
    },
  },
  [TOKEN_TYPE_LABEL]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'labelName',
      [SPECIAL_FILTER]: 'labelName',
      [ALTERNATIVE_FILTER]: 'labelNames',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'label_name[]',
        [SPECIAL_FILTER]: 'label_name[]',
        [ALTERNATIVE_FILTER]: 'label_name',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[label_name][]',
      },
      [OPERATOR_OR]: {
        [ALTERNATIVE_FILTER]: 'or[label_name][]',
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
      [OPERATOR_NOT]: {
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
      [OPERATOR_NOT]: {
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
      [OPERATOR_NOT]: {
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
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[iteration_id]',
        [SPECIAL_FILTER]: 'not[iteration_id]',
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
      [OPERATOR_NOT]: {
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
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[weight]',
      },
    },
  },
  [TOKEN_TYPE_HEALTH]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'healthStatusFilter',
      [SPECIAL_FILTER]: 'healthStatusFilter',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'health_status',
        [SPECIAL_FILTER]: 'health_status',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[health_status]',
      },
    },
  },
  [TOKEN_TYPE_CONTACT]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'crmContactId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'crm_contact_id',
      },
    },
  },
  [TOKEN_TYPE_ORGANIZATION]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'crmOrganizationId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'crm_organization_id',
      },
    },
  },
};
