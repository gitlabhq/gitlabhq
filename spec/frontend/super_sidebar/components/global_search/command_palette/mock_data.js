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
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'item_without_id',
      'data-track-extra': '{"title":"Manage"}',
    },
  },
  {
    href: '/flightjs/Flight/activity',
    icon: 'users',
    keywords: 'Activity',
    text: 'Manage > Activity',
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'activity',
    },
  },
  {
    href: '/flightjs/Flight/-/project_members',
    icon: 'users',
    keywords: 'Members',
    text: 'Manage > Members',
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'members',
    },
  },
  {
    href: '/flightjs/Flight/-/labels',
    icon: 'users',
    keywords: 'Labels',
    text: 'Manage > Labels',
    extraAttrs: {
      'data-track-action': 'click_command_palette_item',
      'data-track-label': 'labels',
    },
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

export const FILES = [
  '.gitattributes',
  '.gitignore',
  '.gitmodules',
  'CHANGELOG',
  'CONTRIBUTING.md',
  'Gemfile.zip',
  'LICENSE',
  'MAINTENANCE.md',
  'PROCESS.md',
  'README',
  'README.md',
  'VERSION',
  'bar/branch-test.txt',
  'custom-highlighting/test.gitlab-custom',
  'encoding/feature-1.txt',
  'encoding/feature-2.txt',
  'encoding/hotfix-1.txt',
  'encoding/hotfix-2.txt',
  'encoding/iso8859.txt',
  'encoding/russian.rb',
  'encoding/test.txt',
  'encoding/テスト.txt',
  'encoding/テスト.xls',
  'files/flat/path/correct/content.txt',
  'files/html/500.html',
  'files/images/6049019_460s.jpg',
  'files/images/emoji.png',
  'files/images/logo-black.png',
  'files/images/logo-white.png',
  'files/images/wm.svg',
  'files/js/application.js',
  'files/js/commit.coffee',
  'files/lfs/lfs_object.iso',
  'files/markdown/ruby-style-guide.md',
  'files/ruby/popen.rb',
  'files/ruby/regex.rb',
  'files/ruby/version_info.rb',
  'files/whitespace',
  'foo/bar/.gitkeep',
  'with space/README.md',
];

export const SETTINGS = [{ text: 'Avatar', href: '/settings/general', anchor: 'avatar' }];
