import { s__ } from '~/locale';

export const context = {
  title: 'Typeahead.js',
  link: '/',
  avatar: 'https://gitlab.com/uploads/-/system/project/avatar/278964/project_avatar.png?width=32',
};

export const contextSwitcherItems = {
  yourWork: { title: s__('Navigation|Your work'), link: '/', icon: 'work' },
  recentProjects: [
    {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      title: 'Orange',
      subtitle: 'tropical-tree',
      link: '/tropical-tree',
      avatar:
        'https://gitlab.com/uploads/-/system/project/avatar/4456656/pajamas-logo.png?width=64',
    },
    {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      title: 'Lemon',
      subtitle: 'tropical-tree',
      link: '/tropical-tree',
      avatar: 'https://gitlab.com/uploads/-/system/project/avatar/7071551/GitLab_UI.png?width=64',
    },
    {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      title: 'Coconut',
      subtitle: 'tropical-tree',
      link: '/tropical-tree',
      avatar:
        'https://gitlab.com/uploads/-/system/project/avatar/4149988/SVGs_project.png?width=64',
    },
  ],
  recentGroups: [
    {
      title: 'Developer Evangelism at GitLab',
      subtitle: 'tropical-tree',
      link: '/tropical-tree',
      avatar:
        'https://gitlab.com/uploads/-/system/group/avatar/10087220/rainbow_tanuki.jpg?width=64',
    },
    {
      title: 'security-products',
      subtitle: 'tropical-tree',
      link: '/tropical-tree',
      avatar:
        'https://gitlab.com/uploads/-/system/group/avatar/11932235/gitlab-icon-rgb.png?width=64',
    },
    {
      title: 'Tanuki-Workshops',
      subtitle: 'tropical-tree',
      link: '/tropical-tree',
      avatar:
        'https://gitlab.com/uploads/-/system/group/avatar/5085244/Screenshot_2019-04-29_at_16.13.07.png?width=64',
    },
  ],
};
