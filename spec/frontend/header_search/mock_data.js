import {
  MSG_ISSUES_ASSIGNED_TO_ME,
  MSG_ISSUES_IVE_CREATED,
  MSG_MR_ASSIGNED_TO_ME,
  MSG_MR_IM_REVIEWER,
  MSG_MR_IVE_CREATED,
  MSG_IN_PROJECT,
  MSG_IN_GROUP,
  MSG_IN_ALL_GITLAB,
} from '~/header_search/constants';

export const MOCK_USERNAME = 'anyone';

export const MOCK_SEARCH_PATH = '/search';

export const MOCK_ISSUE_PATH = '/dashboard/issues';

export const MOCK_MR_PATH = '/dashboard/merge_requests';

export const MOCK_ALL_PATH = '/';

export const MOCK_AUTOCOMPLETE_PATH = '/autocomplete';

export const MOCK_PROJECT = {
  id: 123,
  name: 'MockProject',
  path: '/mock-project',
};

export const MOCK_GROUP = {
  id: 321,
  name: 'MockGroup',
  path: '/mock-group',
};

export const MOCK_SEARCH_QUERY = 'http://gitlab.com/search?search=test';

export const MOCK_SEARCH = 'test';

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

export const MOCK_SCOPED_SEARCH_OPTIONS = [
  {
    scope: MOCK_PROJECT.name,
    description: MSG_IN_PROJECT,
    url: MOCK_PROJECT.path,
  },
  {
    scope: MOCK_GROUP.name,
    description: MSG_IN_GROUP,
    url: MOCK_GROUP.path,
  },
  {
    description: MSG_IN_ALL_GITLAB,
    url: MOCK_ALL_PATH,
  },
];

export const MOCK_AUTOCOMPLETE_OPTIONS = [
  {
    category: 'Projects',
    id: 1,
    label: 'MockProject1',
    url: 'project/1',
  },
  {
    category: 'Projects',
    id: 2,
    label: 'MockProject2',
    url: 'project/2',
  },
  {
    category: 'Groups',
    id: 1,
    label: 'MockGroup1',
    url: 'group/1',
  },
  {
    category: 'Help',
    label: 'GitLab Help',
    url: 'help/gitlab',
  },
];

export const MOCK_GROUPED_AUTOCOMPLETE_OPTIONS = [
  {
    category: 'Projects',
    data: [
      {
        category: 'Projects',
        id: 1,
        label: 'MockProject1',
        url: 'project/1',
      },
      {
        category: 'Projects',
        id: 2,
        label: 'MockProject2',
        url: 'project/2',
      },
    ],
  },
  {
    category: 'Groups',
    data: [
      {
        category: 'Groups',
        id: 1,
        label: 'MockGroup1',
        url: 'group/1',
      },
    ],
  },
  {
    category: 'Help',
    data: [
      {
        category: 'Help',
        label: 'GitLab Help',
        url: 'help/gitlab',
      },
    ],
  },
];
