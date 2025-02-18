import {
  ICON_PROJECT,
  ICON_GROUP,
  ICON_SUBGROUP,
} from '~/super_sidebar/components/global_search/constants';

import {
  PROJECTS_CATEGORY,
  GROUPS_CATEGORY,
  MSG_ISSUES_ASSIGNED_TO_ME,
  MSG_ISSUES_IVE_CREATED,
  MSG_MR_ASSIGNED_TO_ME,
  MSG_MR_IM_REVIEWER,
  MSG_MR_IVE_CREATED,
  MSG_IN_ALL_GITLAB,
  MSG_MR_IM_WORKING_ON,
} from '~/vue_shared/global_search/constants';

import {
  SCOPE_SEARCH_PROJECT,
  SCOPE_SEARCH_GROUP,
  SCOPE_SEARCH_ALL,
} from '~/super_sidebar/components/global_search/command_palette/constants';

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

export const MOCK_SEARCH_QUERY = '/search?search=test';

export const MOCK_SEARCH = 'test';

export const MOCK_SEARCH_CONTEXT = {
  project: null,
  project_metadata: {},
  group: null,
  group_metadata: {},
};

export const MOCK_GROUP_SEARCH_CONTEXT = {
  ...MOCK_SEARCH_CONTEXT,
  group: MOCK_GROUP,
  group_metadata: {
    issues_path: `${MOCK_GROUP.path}/issues`,
    mr_path: `${MOCK_GROUP.path}/merge_requests`,
  },
};

export const MOCK_PROJECT_SEARCH_CONTEXT = {
  ...MOCK_GROUP_SEARCH_CONTEXT,
  project: MOCK_PROJECT,
  project_metadata: {
    issues_path: `${MOCK_PROJECT.path}/issues`,
    mr_path: `${MOCK_PROJECT.path}/merge_requests`,
  },
};

export const MOCK_DEFAULT_SEARCH_OPTIONS = [
  {
    text: MSG_ISSUES_ASSIGNED_TO_ME,
    href: `${MOCK_ISSUE_PATH}/?assignee_username=${MOCK_USERNAME}`,
  },
  {
    text: MSG_ISSUES_IVE_CREATED,
    href: `${MOCK_ISSUE_PATH}/?author_username=${MOCK_USERNAME}`,
  },
  {
    text: MSG_MR_ASSIGNED_TO_ME,
    href: `${MOCK_MR_PATH}/?assignee_username=${MOCK_USERNAME}`,
  },
  {
    text: MSG_MR_IM_REVIEWER,
    href: `${MOCK_MR_PATH}/?reviewer_username=${MOCK_USERNAME}`,
  },
  {
    text: MSG_MR_IVE_CREATED,
    href: `${MOCK_MR_PATH}/?author_username=${MOCK_USERNAME}`,
  },
];
export const MOCK_DASHBOARD_FLAG_ENABLED_SEARCH_OPTIONS = [
  {
    text: MSG_ISSUES_ASSIGNED_TO_ME,
    href: `${MOCK_ISSUE_PATH}/?assignee_username=${MOCK_USERNAME}`,
  },
  {
    text: MSG_ISSUES_IVE_CREATED,
    href: `${MOCK_ISSUE_PATH}/?author_username=${MOCK_USERNAME}`,
  },
  {
    text: MSG_MR_IM_WORKING_ON,
    href: MOCK_MR_PATH,
  },
];
export const MOCK_SCOPED_SEARCH_OPTIONS_DEF = [
  {
    text: SCOPE_SEARCH_PROJECT,
    scope: MOCK_PROJECT.name,
    scopeCategory: PROJECTS_CATEGORY,
    icon: ICON_PROJECT,
    href: MOCK_PROJECT.path,
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'scoped_in_project',
    },
  },
  {
    text: SCOPE_SEARCH_GROUP,
    scope: MOCK_GROUP.name,
    scopeCategory: GROUPS_CATEGORY,
    icon: ICON_GROUP,
    href: MOCK_GROUP.path,
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'scoped_in_group',
    },
  },
  {
    text: SCOPE_SEARCH_ALL,
    description: MSG_IN_ALL_GITLAB,
    href: MOCK_ALL_PATH,
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'scoped_in_all',
    },
  },
];
export const MOCK_SCOPED_SEARCH_OPTIONS = [
  {
    text: SCOPE_SEARCH_PROJECT,
    scope: MOCK_PROJECT.name,
    scopeCategory: PROJECTS_CATEGORY,
    icon: ICON_PROJECT,
    url: MOCK_PROJECT.path,
  },
  {
    text: 'scoped-in-project-long',
    scope: MOCK_PROJECT_LONG.name,
    scopeCategory: PROJECTS_CATEGORY,
    icon: ICON_PROJECT,
    url: MOCK_PROJECT_LONG.path,
  },
  {
    text: SCOPE_SEARCH_GROUP,
    scope: MOCK_GROUP.name,
    scopeCategory: GROUPS_CATEGORY,
    icon: ICON_GROUP,
    url: MOCK_GROUP.path,
  },
  {
    text: 'scoped-in-subgroup',
    scope: MOCK_SUBGROUP.name,
    scopeCategory: GROUPS_CATEGORY,
    icon: ICON_SUBGROUP,
    url: MOCK_SUBGROUP.path,
  },
  {
    text: SCOPE_SEARCH_ALL,
    description: MSG_IN_ALL_GITLAB,
    url: MOCK_ALL_PATH,
  },
];

export const MOCK_SCOPED_SEARCH_GROUP = {
  items: [
    {
      text: SCOPE_SEARCH_PROJECT,
      scope: MOCK_PROJECT.name,
      scopeCategory: PROJECTS_CATEGORY,
      icon: ICON_PROJECT,
      href: MOCK_PROJECT.path,
    },
    {
      text: SCOPE_SEARCH_GROUP,
      scope: MOCK_GROUP.name,
      scopeCategory: GROUPS_CATEGORY,
      icon: ICON_GROUP,
      href: MOCK_GROUP.path,
    },
    {
      text: SCOPE_SEARCH_ALL,
      description: MSG_IN_ALL_GITLAB,
      href: MOCK_ALL_PATH,
    },
  ],
};

export const MOCK_AUTOCOMPLETE_OPTIONS_RES = [
  {
    category: 'Projects',
    id: 1,
    label: 'Gitlab Org / MockProject1',
    value: 'MockProject1',
    url: 'project/1',
    avatar_url: '/project/avatar/1/avatar.png',
  },
  {
    avatar_url: '/groups/avatar/1/avatar.png',
    category: 'Groups',
    id: 1,
    label: 'Gitlab Org / MockGroup1',
    value: 'MockGroup1',
    url: 'group/1',
  },
  {
    avatar_url: '/project/avatar/2/avatar.png',
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
    id: 1,
    label: 'Gitlab Org / MockProject1',
    value: 'MockProject1',
    url: 'project/1',
    avatar_url: '/project/avatar/1/avatar.png',
  },
  {
    category: 'Groups',
    id: 1,
    label: 'Gitlab Org / MockGroup1',
    value: 'MockGroup1',
    url: 'group/1',
    avatar_url: '/groups/avatar/1/avatar.png',
  },
  {
    category: 'Projects',
    id: 2,
    label: 'Gitlab Org / MockProject2',
    value: 'MockProject2',
    url: 'project/2',
    avatar_url: '/project/avatar/2/avatar.png',
  },
  {
    category: 'Help',
    label: 'GitLab Help',
    url: 'help/gitlab',
  },
];

export const MOCK_GROUPED_AUTOCOMPLETE_OPTIONS = [
  {
    name: 'Groups',
    items: [
      {
        category: 'Groups',
        id: 1,
        label: 'Gitlab Org / MockGroup1',
        namespace: 'Gitlab Org / MockGroup1',
        value: 'MockGroup1',
        text: 'MockGroup1',
        href: 'group/1',
        avatar_url: '/groups/avatar/1/avatar.png',
        avatar_size: 32,
        entity_id: 1,
        entity_name: 'MockGroup1',
        extraAttrs: {
          'data-track-action': 'click_command_palette_item',
          'data-track-label': 'groups',
        },
      },
    ],
  },
  {
    name: 'Projects',
    items: [
      {
        category: 'Projects',
        id: 1,
        label: 'Gitlab Org / MockProject1',
        namespace: 'Gitlab Org / MockProject1',
        value: 'MockProject1',
        text: 'MockProject1',
        href: 'project/1',
        avatar_url: '/project/avatar/1/avatar.png',
        avatar_size: 32,
        entity_id: 1,
        entity_name: 'MockProject1',
        extraAttrs: {
          'data-track-action': 'click_command_palette_item',
          'data-track-label': 'projects',
        },
      },
      {
        category: 'Projects',
        id: 2,
        value: 'MockProject2',
        label: 'Gitlab Org / MockProject2',
        namespace: 'Gitlab Org / MockProject2',
        text: 'MockProject2',
        href: 'project/2',
        avatar_url: '/project/avatar/2/avatar.png',
        avatar_size: 32,
        entity_id: 2,
        entity_name: 'MockProject2',
        extraAttrs: {
          'data-track-action': 'click_command_palette_item',
          'data-track-label': 'projects',
        },
      },
    ],
  },
  {
    name: 'Help',
    items: [
      {
        category: 'Help',
        label: 'GitLab Help',
        text: 'GitLab Help',
        href: 'help/gitlab',
        avatar_size: 16,
        entity_name: 'GitLab Help',
        extraAttrs: {
          'data-track-action': 'click_command_palette_item',
          'data-track-label': 'help',
        },
      },
    ],
  },
];

export const MOCK_SORTED_AUTOCOMPLETE_OPTIONS = [
  {
    category: 'Groups',
    id: 1,
    label: 'Gitlab Org / MockGroup1',
    value: 'MockGroup1',
    text: 'MockGroup1',
    href: 'group/1',
    namespace: 'Gitlab Org / MockGroup1',
    avatar_url: '/groups/avatar/1/avatar.png',
    avatar_size: 32,
    entity_id: 1,
    entity_name: 'MockGroup1',
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'groups',
    },
  },
  {
    avatar_size: 32,
    avatar_url: '/project/avatar/1/avatar.png',
    category: 'Projects',
    entity_id: 1,
    entity_name: 'MockProject1',
    href: 'project/1',
    id: 1,
    label: 'Gitlab Org / MockProject1',
    namespace: 'Gitlab Org / MockProject1',
    text: 'MockProject1',
    value: 'MockProject1',
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'projects',
    },
  },
  {
    avatar_size: 32,
    avatar_url: '/project/avatar/2/avatar.png',
    category: 'Projects',
    entity_id: 2,
    entity_name: 'MockProject2',
    href: 'project/2',
    id: 2,
    label: 'Gitlab Org / MockProject2',
    namespace: 'Gitlab Org / MockProject2',
    text: 'MockProject2',
    value: 'MockProject2',
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'projects',
    },
  },
  {
    avatar_size: 16,
    entity_name: 'GitLab Help',
    category: 'Help',
    label: 'GitLab Help',
    text: 'GitLab Help',
    href: 'help/gitlab',
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'help',
    },
  },
];

export const MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_HELP = [
  {
    category: 'Help',
    data: [
      {
        html_id: 'autocomplete-Help-1',
        category: 'Help',
        text: 'Rake Tasks Help',
        label: 'Rake Tasks Help',
        href: '/help/raketasks/index',
      },
      {
        html_id: 'autocomplete-Help-2',
        category: 'Help',
        text: 'System Hooks Help',
        label: 'System Hooks Help',
        href: '/help/system_hooks/system_hooks',
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
        url: '/-/user_settings/profile',
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
