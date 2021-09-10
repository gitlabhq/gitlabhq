import {
  MSG_ISSUES_ASSIGNED_TO_ME,
  MSG_ISSUES_IVE_CREATED,
  MSG_MR_ASSIGNED_TO_ME,
  MSG_MR_IM_REVIEWER,
  MSG_MR_IVE_CREATED,
} from '~/header_search/constants';

export const MOCK_USERNAME = 'anyone';

export const MOCK_ISSUE_PATH = '/dashboard/issues';

export const MOCK_MR_PATH = '/dashboard/merge_requests';

export const MOCK_SEARCH_CONTEXT = {
  project: null,
  project_metadata: {},
  group: null,
  group_metadata: {},
};

export const MOCK_DEFAULT_SEARCH_OPTIONS = [
  {
    title: MSG_ISSUES_ASSIGNED_TO_ME,
    url: `${MOCK_ISSUE_PATH}/?assignee_username=${MOCK_USERNAME}`,
  },
  {
    title: MSG_ISSUES_IVE_CREATED,
    url: `${MOCK_ISSUE_PATH}/?author_username=${MOCK_USERNAME}`,
  },
  {
    title: MSG_MR_ASSIGNED_TO_ME,
    url: `${MOCK_MR_PATH}/?assignee_username=${MOCK_USERNAME}`,
  },
  {
    title: MSG_MR_IM_REVIEWER,
    url: `${MOCK_MR_PATH}/?reviewer_username=${MOCK_USERNAME}`,
  },
  {
    title: MSG_MR_IVE_CREATED,
    url: `${MOCK_MR_PATH}/?author_username=${MOCK_USERNAME}`,
  },
];
