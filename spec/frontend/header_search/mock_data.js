import { ICON_PROJECT, ICON_GROUP, ICON_SUBGROUP } from '~/header_search/constants';
import {
  PROJECTS_CATEGORY,
  GROUPS_CATEGORY,
  MSG_ISSUES_ASSIGNED_TO_ME,
  MSG_ISSUES_IVE_CREATED,
  MSG_MR_ASSIGNED_TO_ME,
  MSG_MR_IM_REVIEWER,
  MSG_MR_IVE_CREATED,
  MSG_IN_ALL_GITLAB,
} from '~/vue_shared/global_search/constants';

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

export const MOCK_PROJECT_LONG = {
  id: 124,
  name: 'Mock Project Name That Is Ridiculously Long And It Goes Forever',
  path: '/mock-project-name-that-is-ridiculously-long-and-it-goes-forever',
};

export const MOCK_GROUP = {
  id: 321,
  name: 'MockGroup',
  path: '/mock-group',
};

export const MOCK_SUBGROUP = {
  id: 322,
  name: 'MockSubGroup',
  path: `${MOCK_GROUP}/mock-subgroup`,
};

export const MOCK_SEARCH_QUERY = 'http://gitlab.com/search?search=test';

export const MOCK_SEARCH = 'test';

export const MOCK_SEARCH_CONTEXT = {
  project: null,
  project_metadata: {},
  group: null,
  group_metadata: {},
};

export const MOCK_SEARCH_CONTEXT_FULL = {
  group: {
    id: 31,
    name: 'testGroup',
    full_name: 'testGroup',
  },
  group_metadata: {
    group_path: 'testGroup',
    name: 'testGroup',
    issues_path: '/groups/testGroup/-/issues',
    mr_path: '/groups/testGroup/-/merge_requests',
  },
};

export const MOCK_DEFAULT_SEARCH_OPTIONS = [
  {
    html_id: 'default-issues-assigned',
    title: MSG_ISSUES_ASSIGNED_TO_ME,
    url: `${MOCK_ISSUE_PATH}/?assignee_username=${MOCK_USERNAME}`,
  },
  {
    html_id: 'default-issues-created',
    title: MSG_ISSUES_IVE_CREATED,
    url: `${MOCK_ISSUE_PATH}/?author_username=${MOCK_USERNAME}`,
  },
  {
    html_id: 'default-mrs-assigned',
    title: MSG_MR_ASSIGNED_TO_ME,
    url: `${MOCK_MR_PATH}/?assignee_username=${MOCK_USERNAME}`,
  },
  {
    html_id: 'default-mrs-reviewer',
    title: MSG_MR_IM_REVIEWER,
    url: `${MOCK_MR_PATH}/?reviewer_username=${MOCK_USERNAME}`,
  },
  {
    html_id: 'default-mrs-created',
    title: MSG_MR_IVE_CREATED,
    url: `${MOCK_MR_PATH}/?author_username=${MOCK_USERNAME}`,
  },
];

export const MOCK_SCOPED_SEARCH_OPTIONS = [
  {
    html_id: 'scoped-in-project',
    scope: MOCK_PROJECT.name,
    scopeCategory: PROJECTS_CATEGORY,
    icon: ICON_PROJECT,
    url: MOCK_PROJECT.path,
  },
  {
    html_id: 'scoped-in-project-long',
    scope: MOCK_PROJECT_LONG.name,
    scopeCategory: PROJECTS_CATEGORY,
    icon: ICON_PROJECT,
    url: MOCK_PROJECT_LONG.path,
  },
  {
    html_id: 'scoped-in-group',
    scope: MOCK_GROUP.name,
    scopeCategory: GROUPS_CATEGORY,
    icon: ICON_GROUP,
    url: MOCK_GROUP.path,
  },
  {
    html_id: 'scoped-in-subgroup',
    scope: MOCK_SUBGROUP.name,
    scopeCategory: GROUPS_CATEGORY,
    icon: ICON_SUBGROUP,
    url: MOCK_SUBGROUP.path,
  },
  {
    html_id: 'scoped-in-all',
    description: MSG_IN_ALL_GITLAB,
    url: MOCK_ALL_PATH,
  },
];

export const MOCK_SCOPED_SEARCH_OPTIONS_DEF = [
  {
    html_id: 'scoped-in-project',
    scope: MOCK_PROJECT.name,
    scopeCategory: PROJECTS_CATEGORY,
    icon: ICON_PROJECT,
    url: MOCK_PROJECT.path,
  },
  {
    html_id: 'scoped-in-group',
    scope: MOCK_GROUP.name,
    scopeCategory: GROUPS_CATEGORY,
    icon: ICON_GROUP,
    url: MOCK_GROUP.path,
  },
  {
    html_id: 'scoped-in-all',
    description: MSG_IN_ALL_GITLAB,
    url: MOCK_ALL_PATH,
  },
];

export const MOCK_AUTOCOMPLETE_OPTIONS_RES = [
  {
    category: 'Projects',
    id: 1,
    label: 'Gitlab Org / MockProject1',
    value: 'MockProject1',
    url: 'project/1',
  },
  {
    category: 'Groups',
    id: 1,
    label: 'Gitlab Org / MockGroup1',
    value: 'MockGroup1',
    url: 'group/1',
  },
  {
    category: 'Projects',
    id: 2,
    label: 'Gitlab Org / MockProject2',
    value: 'MockProject2',
    url: 'project/2',
  },
  {
    category: 'Help',
    label: 'GitLab Help',
    url: 'help/gitlab',
  },
];

export const MOCK_AUTOCOMPLETE_OPTIONS = [
  {
    category: 'Projects',
    html_id: 'autocomplete-Projects-0',
    id: 1,
    label: 'Gitlab Org / MockProject1',
    value: 'MockProject1',
    url: 'project/1',
  },
  {
    category: 'Groups',
    html_id: 'autocomplete-Groups-1',
    id: 1,
    label: 'Gitlab Org / MockGroup1',
    value: 'MockGroup1',
    url: 'group/1',
  },
  {
    category: 'Projects',
    html_id: 'autocomplete-Projects-2',
    id: 2,
    label: 'Gitlab Org / MockProject2',
    value: 'MockProject2',
    url: 'project/2',
  },
  {
    category: 'Help',
    html_id: 'autocomplete-Help-3',
    label: 'GitLab Help',
    url: 'help/gitlab',
  },
];

export const MOCK_GROUPED_AUTOCOMPLETE_OPTIONS = [
  {
    category: 'Groups',
    data: [
      {
        category: 'Groups',
        html_id: 'autocomplete-Groups-1',

        id: 1,
        label: 'Gitlab Org / MockGroup1',
        value: 'MockGroup1',
        url: 'group/1',
      },
    ],
  },
  {
    category: 'Projects',
    data: [
      {
        category: 'Projects',
        html_id: 'autocomplete-Projects-0',

        id: 1,
        label: 'Gitlab Org / MockProject1',
        value: 'MockProject1',
        url: 'project/1',
      },
      {
        category: 'Projects',
        html_id: 'autocomplete-Projects-2',

        id: 2,
        label: 'Gitlab Org / MockProject2',
        value: 'MockProject2',
        url: 'project/2',
      },
    ],
  },
  {
    category: 'Help',
    data: [
      {
        category: 'Help',
        html_id: 'autocomplete-Help-3',

        label: 'GitLab Help',
        url: 'help/gitlab',
      },
    ],
  },
];

export const MOCK_SORTED_AUTOCOMPLETE_OPTIONS = [
  {
    category: 'Groups',
    html_id: 'autocomplete-Groups-1',
    id: 1,
    label: 'Gitlab Org / MockGroup1',
    value: 'MockGroup1',
    url: 'group/1',
  },
  {
    category: 'Projects',
    html_id: 'autocomplete-Projects-0',
    id: 1,
    label: 'Gitlab Org / MockProject1',
    value: 'MockProject1',
    url: 'project/1',
  },
  {
    category: 'Projects',
    html_id: 'autocomplete-Projects-2',
    id: 2,
    label: 'Gitlab Org / MockProject2',
    value: 'MockProject2',
    url: 'project/2',
  },
  {
    category: 'Help',
    html_id: 'autocomplete-Help-3',
    label: 'GitLab Help',
    url: 'help/gitlab',
  },
];

export const MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_HELP = [
  {
    category: 'Help',
    data: [
      {
        html_id: 'autocomplete-Help-1',
        category: 'Help',
        label: 'Rake Tasks Help',
        url: '/help/raketasks/index',
      },
      {
        html_id: 'autocomplete-Help-2',
        category: 'Help',
        label: 'System Hooks Help',
        url: '/help/system_hooks/system_hooks',
      },
    ],
  },
];

export const MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_SETTINGS_HELP = [
  {
    category: 'Settings',
    data: [
      {
        html_id: 'autocomplete-Settings-0',
        category: 'Settings',
        label: 'User settings',
        url: '/-/profile',
      },
      {
        html_id: 'autocomplete-Settings-3',
        category: 'Settings',
        label: 'Admin Section',
        url: '/admin',
      },
    ],
  },
  {
    category: 'Help',
    data: [
      {
        html_id: 'autocomplete-Help-1',
        category: 'Help',
        label: 'Rake Tasks Help',
        url: '/help/raketasks/index',
      },
      {
        html_id: 'autocomplete-Help-2',
        category: 'Help',
        label: 'System Hooks Help',
        url: '/help/system_hooks/system_hooks',
      },
    ],
  },
];

export const MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_2 = [
  {
    category: 'Groups',
    data: [
      {
        html_id: 'autocomplete-Groups-0',
        category: 'Groups',
        id: 148,
        label: 'Jashkenas / Test Subgroup / test-subgroup',
        url: '/jashkenas/test-subgroup/test-subgroup',
        avatar_url: '',
      },
      {
        html_id: 'autocomplete-Groups-1',
        category: 'Groups',
        id: 147,
        label: 'Jashkenas / Test Subgroup',
        url: '/jashkenas/test-subgroup',
        avatar_url: '',
      },
    ],
  },
  {
    category: 'Projects',
    data: [
      {
        html_id: 'autocomplete-Projects-2',
        category: 'Projects',
        id: 1,
        value: 'Gitlab Test',
        label: 'Gitlab Org / Gitlab Test',
        url: '/gitlab-org/gitlab-test',
        avatar_url: '/uploads/-/system/project/avatar/1/icons8-gitlab-512.png',
      },
    ],
  },
];
