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
        href: '/groups/gitlab-org/-/epics/new',
      },
      {
        text: 'Invite members',
        href: '/groups/gitlab-org/-/group_members',
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
      },
      {
        text: 'Review requests',
        href: '/dashboard/merge_requests?reviewer_username=root',
        count: 0,
      },
    ],
  },
];

export const sidebarData = {
  current_menu_items: [],
  current_context_header: {
    title: 'Your Work',
    icon: 'work',
  },
  name: 'Administrator',
  username: 'root',
  avatar_url: 'path/to/img_administrator',
  assigned_open_issues_count: 1,
  todos_pending_count: 3,
  issues_dashboard_path: 'path/to/issues',
  total_merge_requests_count: 4,
  create_new_menu_groups: createNewMenuGroups,
  merge_request_menu: mergeRequestMenuGroup,
  support_path: '/support',
  display_whats_new: true,
  whats_new_most_recent_release_items_count: 5,
  whats_new_version_digest: 1,
  show_version_check: false,
  gitlab_version: { major: 16, minor: 0 },
  gitlab_version_check: { severity: 'success' },
};

export const userMenuMockStatus = {
  can_update: false,
  busy: false,
  customized: false,
  emoji: 'art',
  message: 'Working on user menu in super sidebar',
  availability: 'busy',
  clear_after: '2023-02-09 20:06:35 UTC',
};

export const userMenuMockData = {
  name: 'Orange Fox',
  username: 'thefox',
  avatar_url: invalidUrl,
  has_link_to_profile: true,
  link_to_profile: '/thefox',
  status: userMenuMockStatus,
  trial: {
    has_start_trial: false,
  },
  settings: {
    profile_path: invalidUrl,
    profile_preferences_path: invalidUrl,
  },
  can_sign_out: false,
  sign_out_link: invalidUrl,
  gitlab_com_but_not_canary: true,
  canary_toggle_com_url: 'https://next.gitlab.com',
};
