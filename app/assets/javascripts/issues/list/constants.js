import { __ } from '~/locale';
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
  OPERATOR_AFTER,
  OPERATOR_BEFORE,
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TYPE_APPROVER,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_CONTACT,
  TOKEN_TYPE_DRAFT,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_GROUP,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_ORGANIZATION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_SOURCE_BRANCH,
  TOKEN_TYPE_TARGET_BRANCH,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_WEIGHT,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_CREATED,
  TOKEN_TYPE_CLOSED,
  TOKEN_TYPE_DEPLOYED_BEFORE,
  TOKEN_TYPE_DEPLOYED_AFTER,
  TOKEN_TYPE_ENVIRONMENT,
  TOKEN_TYPE_STATE,
} from '~/vue_shared/components/filtered_search_bar/constants';

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
export const MERGED_AT_ASC = 'MERGED_AT_ASC';
export const MERGED_AT_DESC = 'MERGED_AT_DESC';

export const API_PARAM = 'apiParam';
export const URL_PARAM = 'urlParam';
export const NORMAL_FILTER = 'normalFilter';
export const WILDCARD_FILTER = 'wildcardFilter';
export const ALTERNATIVE_FILTER = 'alternativeFilter';

export const ISSUES_VIEW_TYPE_KEY = 'issuesViewType';
export const ISSUES_LIST_VIEW_KEY = 'List';
export const ISSUES_GRID_VIEW_KEY = 'Grid';

export const CLOSED = __('Closed');
export const CLOSED_MOVED = __('Closed (moved)');

export const i18n = {
  actionsLabel: __('Actions'),
  closed: CLOSED,
  closedMoved: CLOSED_MOVED,
  confidentialNo: __('No'),
  confidentialYes: __('Yes'),
  downvotes: __('Downvotes'),
  errorFetchingCounts: __('An error occurred while getting issue counts'),
  errorFetchingIssues: __('An error occurred while loading issues'),
  issueRepositioningMessage: __(
    'Issues are being rebalanced at the moment, so manual reordering is disabled.',
  ),
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
  [MERGED_AT_ASC]: 'merged_at_asc',
  [MERGED_AT_DESC]: 'merged_at_desc',
};

export const wildcardFilterValues = [
  FILTER_NONE,
  FILTER_ANY,
  FILTER_CURRENT,
  FILTER_UPCOMING,
  FILTER_STARTED,
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
  [TOKEN_TYPE_APPROVED_BY]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'approvedBy',
      [WILDCARD_FILTER]: 'approvedBy',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'approved_by_usernames[]',
        [WILDCARD_FILTER]: 'approved_by_usernames[]',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[approved_by_usernames][]',
        [WILDCARD_FILTER]: 'not[approved_by_usernames][]',
      },
    },
  },
  [TOKEN_TYPE_APPROVER]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'approver',
      [WILDCARD_FILTER]: 'approver',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'approver[]',
        [WILDCARD_FILTER]: 'approver[]',
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
        [NORMAL_FILTER]: 'not[author_username][]',
      },
      [OPERATOR_OR]: {
        [ALTERNATIVE_FILTER]: 'or[author_username][]',
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
      [WILDCARD_FILTER]: 'assigneeWildcardId',
      [ALTERNATIVE_FILTER]: 'assigneeId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'assignee_username[]',
        [WILDCARD_FILTER]: 'assignee_id',
        [ALTERNATIVE_FILTER]: 'assignee_username',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[assignee_username][]',
        [ALTERNATIVE_FILTER]: 'not[assignee_username]',
      },
      [OPERATOR_OR]: {
        [NORMAL_FILTER]: 'or[assignee_username][]',
      },
    },
  },
  [TOKEN_TYPE_GROUP]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'fullPath',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'group_path',
      },
    },
  },
  [TOKEN_TYPE_REVIEWER]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'reviewerUsername',
      [WILDCARD_FILTER]: 'reviewerWildcardId',
      [ALTERNATIVE_FILTER]: 'reviewerId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'reviewer_username',
        [WILDCARD_FILTER]: 'reviewer_id',
        [ALTERNATIVE_FILTER]: 'reviewer_username',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[reviewer_username]',
      },
    },
  },
  [TOKEN_TYPE_MERGE_USER]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'mergeUser',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'merge_user',
      },
    },
  },
  [TOKEN_TYPE_MILESTONE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'milestoneTitle',
      [WILDCARD_FILTER]: 'milestoneWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'milestone_title',
        [WILDCARD_FILTER]: 'milestone_title',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[milestone_title]',
        [WILDCARD_FILTER]: 'not[milestone_title]',
      },
    },
  },
  [TOKEN_TYPE_LABEL]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'labelName',
      [WILDCARD_FILTER]: 'labelName',
      [ALTERNATIVE_FILTER]: 'labelNames',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'label_name[]',
        [WILDCARD_FILTER]: 'label_name[]',
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
  [TOKEN_TYPE_SOURCE_BRANCH]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'sourceBranches',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'source_branches[]',
        [ALTERNATIVE_FILTER]: 'source_branch',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[source_branches][]',
        [ALTERNATIVE_FILTER]: 'not[source_branch]',
      },
    },
  },
  [TOKEN_TYPE_TARGET_BRANCH]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'targetBranches',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'target_branches[]',
        [ALTERNATIVE_FILTER]: 'target_branch',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[target_branches][]',
        [ALTERNATIVE_FILTER]: 'not[target_branch]',
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
      [WILDCARD_FILTER]: 'releaseTagWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'release_tag',
        [WILDCARD_FILTER]: 'release_tag',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[release_tag]',
      },
    },
  },
  [TOKEN_TYPE_MY_REACTION]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'myReactionEmoji',
      [WILDCARD_FILTER]: 'myReactionEmoji',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'my_reaction_emoji',
        [WILDCARD_FILTER]: 'my_reaction_emoji',
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
  [TOKEN_TYPE_DRAFT]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'draft',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'draft',
      },
    },
  },
  [TOKEN_TYPE_ITERATION]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'iterationId',
      [WILDCARD_FILTER]: 'iterationWildcardId',
      [ALTERNATIVE_FILTER]: 'iterationCadenceId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'iteration_id',
        [WILDCARD_FILTER]: 'iteration_id',
        [ALTERNATIVE_FILTER]: 'iteration_cadence_id',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[iteration_id]',
        [WILDCARD_FILTER]: 'not[iteration_id]',
      },
    },
  },
  [TOKEN_TYPE_EPIC]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'epicId',
      [WILDCARD_FILTER]: 'epicWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'epic_id',
        [WILDCARD_FILTER]: 'epic_id',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[epic_id]',
      },
    },
  },
  [TOKEN_TYPE_WEIGHT]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'weight',
      [WILDCARD_FILTER]: 'weightWildcardId',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'weight',
        [WILDCARD_FILTER]: 'weight',
      },
      [OPERATOR_NOT]: {
        [NORMAL_FILTER]: 'not[weight]',
      },
    },
  },
  [TOKEN_TYPE_HEALTH]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'healthStatusFilter',
      [WILDCARD_FILTER]: 'healthStatusFilter',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'health_status',
        [WILDCARD_FILTER]: 'health_status',
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
  [TOKEN_TYPE_CREATED]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'createdBefore',
      [ALTERNATIVE_FILTER]: 'createdAfter',
    },
    [URL_PARAM]: {
      [OPERATOR_AFTER]: {
        [ALTERNATIVE_FILTER]: 'created_after',
      },
      [OPERATOR_BEFORE]: {
        [NORMAL_FILTER]: 'created_before',
      },
    },
  },
  [TOKEN_TYPE_CLOSED]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'closedBefore',
      [ALTERNATIVE_FILTER]: 'closedAfter',
    },
    [URL_PARAM]: {
      [OPERATOR_AFTER]: {
        [ALTERNATIVE_FILTER]: 'closed_after',
      },
      [OPERATOR_BEFORE]: {
        [NORMAL_FILTER]: 'closed_before',
      },
    },
  },
  [TOKEN_TYPE_ENVIRONMENT]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'environmentName',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'environment',
      },
    },
  },
  [TOKEN_TYPE_DEPLOYED_BEFORE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'deployedBefore',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'deployed_before',
      },
    },
  },
  [TOKEN_TYPE_DEPLOYED_AFTER]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'deployedAfter',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'deployed_after',
      },
    },
  },
  [TOKEN_TYPE_STATE]: {
    [API_PARAM]: {
      [NORMAL_FILTER]: 'state',
    },
    [URL_PARAM]: {
      [OPERATOR_IS]: {
        [NORMAL_FILTER]: 'state',
      },
    },
  },
};
