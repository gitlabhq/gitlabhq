import invalidUrl from '~/lib/utils/invalid_url';

export const createNewMenuGroups = [
  {
    name: 'This group',
    items: [
      {
        text: 'New project/repository',
        href: '/projects/new?namespace_id=22',
      },
      {
        text: 'New subgroup',
        href: '/groups/new?parent_id=22#create-group-pane',
      },
      {
        text: 'New epic',
        component: 'create_new_work_item_modal',
      },
      {
        text: 'Invite members',
        component: 'invite_members',
      },
    ],
  },
  {
    name: 'GitLab',
    items: [
      {
        text: 'New project/repository',
        href: '/projects/new',
      },
      {
        text: 'New group',
        href: '/groups/new',
      },
      {
        text: 'New snippet',
        href: '/-/snippets/new',
      },
    ],
  },
];

export const createNewMenuGroupsLegacy = [
  {
    name: 'This group',
    items: [
      {
        text: 'New project/repository',
        href: '/projects/new?namespace_id=22',
      },
      {
        text: 'New subgroup',
        href: '/groups/new?parent_id=22#create-group-pane',
      },
      {
        text: 'New epic',
        href: '/groups/gitlab-org/-/epics/new',
      },
      {
        text: 'Invite members',
        component: 'invite_members',
      },
    ],
  },
  {
    name: 'GitLab',
    items: [
      {
        text: 'New project/repository',
        href: '/projects/new',
      },
      {
        text: 'New group',
        href: '/groups/new',
      },
      {
        text: 'New snippet',
        href: '/-/snippets/new',
      },
    ],
  },
];

export const mergeRequestMenuGroup = [
  {
    name: 'Merge requests',
    items: [
      {
        text: 'Assigned',
        href: '/dashboard/merge_requests?assignee_username=root',
        count: 4,
        extraAttrs: {
          'data-track-action': 'click_link',
          'data-track-label': 'merge_requests_assigned',
          'data-track-property': 'nav_core_menu',
          class: 'dashboard-shortcuts-merge_requests',
        },
      },
      {
        text: 'Review requests',
        href: '/dashboard/merge_requests?reviewer_username=root',
        count: 0,
        extraAttrs: {
          'data-track-action': 'click_link',
          'data-track-label': 'merge_requests_to_review',
          'data-track-property': 'nav_core_menu',
          class: 'dashboard-shortcuts-review_requests',
        },
      },
    ],
  },
];

export const contextSwitcherLinks = [
  { title: 'Explore', link: '/explore', icon: 'compass', link_classes: 'persistent-link-class' },
  { title: 'Admin area', link: '/admin', icon: 'admin' },
  { title: 'Leave admin mode', link: '/admin/session/destroy', data_method: 'post' },
];

export const sidebarData = {
  is_logged_in: true,
  is_admin: false,
  admin_url: '/admin',
  current_menu_items: [],
  current_context: {},
  current_context_header: 'Your work',
  name: 'Administrator',
  username: 'root',
  avatar_url: 'path/to/img_administrator',
  logo_url: 'path/to/logo',
  user_counts: {
    last_update: Date.now(),
    todos: 3,
    assigned_issues: 1,
    assigned_merge_requests: 3,
    review_requested_merge_requests: 1,
  },
  issues_dashboard_path: 'path/to/issues',
  todos_dashboard_path: 'path/to/todos',
  create_new_menu_groups: createNewMenuGroups,
  merge_request_menu: mergeRequestMenuGroup,
  projects_path: 'path/to/projects',
  groups_path: 'path/to/groups',
  support_path: '/support',
  docs_path: '/help/docs',
  display_whats_new: true,
  whats_new_most_recent_release_items_count: 5,
  whats_new_version_digest: 1,
  show_version_check: false,
  gitlab_version: { major: 16, minor: 0 },
  gitlab_version_check: { severity: 'success' },
  gitlab_com_and_canary: false,
  canary_toggle_com_url: 'https://next.gitlab.com',
  context_switcher_links: contextSwitcherLinks,
  search: {
    search_path: '/search',
  },
  pinned_items: [],
  panel_type: 'your_work',
  update_pins_url: 'path/to/pins',
  stop_impersonation_path: '/admin/impersonation',
  shortcut_links: [
    {
      title: 'Shortcut link',
      href: '/shortcut-link',
      css_class: 'shortcut-link-class',
    },
  ],
  track_visits_path: '/-/track_visits',
};

export const loggedOutSidebarData = {
  is_logged_in: false,
  current_menu_items: [],
  current_context: {},
  current_context_header: 'Your work',
  support_path: '/support',
  display_whats_new: true,
  whats_new_most_recent_release_items_count: 5,
  whats_new_version_digest: 1,
  show_version_check: false,
  gitlab_version: { major: 16, minor: 0 },
  gitlab_version_check: { severity: 'success' },
  search: {
    search_path: '/search',
  },
  panel_type: 'your_work',
};

export const userMenuMockStatus = {
  can_update: false,
  busy: false,
  customized: false,
  emoji: 'art',
  message: 'Working on user menu in super sidebar',
  message_html: '<gl-emoji></gl-emoji> Working on user menu in super sidebar',
  availability: 'busy',
  clear_after: '2023-02-09 20:06:35 UTC',
};

export const userMenuMockPipelineMinutes = {
  show_buy_pipeline_minutes: false,
  show_notification_dot: false,
  callout_attrs: {
    feature_id: 'pipeline_minutes',
    dismiss_endpoint: '/-/dismiss',
  },
  buy_pipeline_minutes_path: '/buy/pipeline_minutes',
  tracking_attrs: {
    'track-action': 'trackAction',
    'track-label': 'label',
    'track-property': 'property',
  },
};

export const userMenuMockData = {
  name: 'Orange Fox',
  username: 'thefox',
  admin_mode: {
    user_is_admin: false,
    admin_mode_feature_enabled: false,
    admin_mode_active: false,
  },
  avatar_url: invalidUrl,
  has_link_to_profile: true,
  link_to_profile: '/thefox',
  status: userMenuMockStatus,
  settings: {
    profile_path: invalidUrl,
    profile_preferences_path: invalidUrl,
  },
  pipeline_minutes: userMenuMockPipelineMinutes,
  can_sign_out: false,
  sign_out_link: invalidUrl,
  gitlab_com_but_not_canary: true,
  canary_toggle_com_url: 'https://next.gitlab.com',
};

export const frecentGroupsMock = [
  {
    id: 'gid://gitlab/Group/1',
    name: 'Frecent group 1',
    namespace: 'Frecent Namespace 1',
    avatarUrl: '/uploads/-/avatar1.png',
    fullPath: 'frecent-namespace-1/frecent-group-1',
  },
];

export const frecentProjectsMock = [
  {
    id: 'gid://gitlab/Project/1',
    name: 'Frecent project 1',
    namespace: 'Frecent Namespace 1 / Frecent project 1',
    avatarUrl: '/uploads/-/avatar1.png',
    fullPath: 'frecent-namespace-1/frecent-project-1',
  },
];

export const unsortedFrequentItems = [
  { id: 1, frequency: 12, lastAccessedOn: 1491400843391 },
  { id: 2, frequency: 14, lastAccessedOn: 1488240890738 },
  { id: 3, frequency: 44, lastAccessedOn: 1497675908472 },
  { id: 4, frequency: 8, lastAccessedOn: 1497979281815 },
  { id: 5, frequency: 34, lastAccessedOn: 1488089211943 },
  { id: 6, frequency: 14, lastAccessedOn: 1493517292488 },
  { id: 7, frequency: 42, lastAccessedOn: 1486815299875 },
  { id: 8, frequency: 33, lastAccessedOn: 1500762279114 },
  { id: 10, frequency: 46, lastAccessedOn: 1483251641543 },
];

/**
 * This const has a specific order which tests authenticity
 * of `getTopFrequentItems` method so
 * DO NOT change order of items in this const.
 */
export const sortedFrequentItems = [
  { id: 10, frequency: 46, lastAccessedOn: 1483251641543 },
  { id: 3, frequency: 44, lastAccessedOn: 1497675908472 },
  { id: 7, frequency: 42, lastAccessedOn: 1486815299875 },
  { id: 5, frequency: 34, lastAccessedOn: 1488089211943 },
  { id: 8, frequency: 33, lastAccessedOn: 1500762279114 },
  { id: 6, frequency: 14, lastAccessedOn: 1493517292488 },
  { id: 2, frequency: 14, lastAccessedOn: 1488240890738 },
  { id: 1, frequency: 12, lastAccessedOn: 1491400843391 },
  { id: 4, frequency: 8, lastAccessedOn: 1497979281815 },
];

export const sidebarDataCountResponse = ({
  openIssuesCount = null,
  openMergeRequestsCount = null,
}) => {
  return {
    data: {
      namespace: {
        id: 'gid://gitlab/Project/11',
        sidebar: {
          openIssuesCount,
          openMergeRequestsCount,
          __typename: 'NamespaceSidebar',
        },
        __typename: 'Namespace',
      },
    },
  };
};
