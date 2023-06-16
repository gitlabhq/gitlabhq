export const COMMANDS = [
  {
    name: 'Global',
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
      {
        text: 'Invite members',
        href: '/-/snippets/new',
        component: 'invite_members',
      },
    ],
  },
];

export const LINKS = [
  {
    title: 'Manage',
    icon: 'users',
    link: '/flightjs/Flight/activity',
    is_active: false,
    pill_count: null,
    items: [
      {
        id: 'activity',
        title: 'Activity',
        icon: null,
        link: '/flightjs/Flight/activity',
        pill_count: null,
        link_classes: 'shortcuts-project-activity',
        is_active: false,
      },
      {
        id: 'members',
        title: 'Members',
        icon: null,
        link: '/flightjs/Flight/-/project_members',
        pill_count: null,
        link_classes: null,
        is_active: false,
      },
      {
        id: 'labels',
        title: 'Labels',
        icon: null,
        link: '/flightjs/Flight/-/labels',
        pill_count: null,
        link_classes: null,
        is_active: false,
      },
    ],
    separated: false,
  },
];

export const TRANSFORMED_LINKS = [
  {
    href: '/flightjs/Flight/activity',
    icon: 'users',
    keywords: 'Manage',
    text: 'Manage',
  },
  {
    href: '/flightjs/Flight/activity',
    icon: 'users',
    keywords: 'Activity',
    text: 'Manage > Activity',
  },
  {
    href: '/flightjs/Flight/-/project_members',
    icon: 'users',
    keywords: 'Members',
    text: 'Manage > Members',
  },
  {
    href: '/flightjs/Flight/-/labels',
    icon: 'users',
    keywords: 'Labels',
    text: 'Manage > Labels',
  },
];

export const USERS = [
  {
    id: 37,
    username: 'reported_user_14',
    name: 'Cole Dickinson',
    web_url: 'http://127.0.0.1:3000/reported_user_14',
    avatar_url:
      'https://www.gravatar.com/avatar/a9638f4ec70148d51e56bf05ad41e993?s=80\u0026d=identicon',
  },
  {
    id: 47,
    username: 'sharlatenok',
    name: 'Olena Horal-Koretska',
    web_url: 'http://127.0.0.1:3000/sharlatenok',
  },
  {
    id: 30,
    username: 'reported_user_7',
    name: 'Violeta Feeney',
    web_url: 'http://127.0.0.1:3000/reported_user_7',
  },
];

export const PROJECT = {
  category: 'Projects',
  id: 1,
  label: 'Gitlab Org / MockProject1',
  value: 'MockProject1',
  url: 'project/1',
  avatar_url: '/project/avatar/1/avatar.png',
};

export const ISSUE = {
  avatar_url: '',
  category: 'Recent issues',
  id: 516,
  label: 'Dismiss Cipher with no integrity',
  project_id: 7,
  project_name: 'Flight',
  url: '/flightjs/Flight/-/issues/37',
};
