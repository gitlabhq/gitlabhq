export const COMMANDS = [
  {
    name: 'Global',
    items: [
      {
        text: 'New project/repository',
        href: '/projects/new',
        keywords: ['new', 'project', 'repository'],
      },
      {
        text: 'New group',
        href: '/groups/new',
        keywords: ['new', 'group'],
      },
      {
        text: 'New snippet',
        href: '/-/snippets/new',
        keywords: ['new', 'snippet'],
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
