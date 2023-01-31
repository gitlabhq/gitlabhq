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

export const sidebarData = {
  name: 'Administrator',
  username: 'root',
  avatar_url: 'path/to/img_administrator',
  assigned_open_issues_count: 1,
  assigned_open_merge_requests_count: 2,
  todos_pending_count: 3,
  issues_dashboard_path: 'path/to/issues',
  create_new_menu_groups: createNewMenuGroups,
  support_path: '/support',
  display_whats_new: true,
};
