/* eslint-disable @gitlab/require-i18n-strings */

// This is temporary mock data that will be removed when completing the following:
// https://gitlab.com/gitlab-org/gitlab/-/issues/420777
// https://gitlab.com/gitlab-org/gitlab/-/issues/421441

export const organization = {
  id: 'gid://gitlab/Organization/1',
  __typename: 'Organization',
};

export const organizationProjects = {
  nodes: [
    {
      id: 'gid://gitlab/Project/8',
      nameWithNamespace: 'Twitter / Typeahead.Js',
      webUrl: 'http://127.0.0.1:3000/twitter/Typeahead.Js',
      topics: ['JavaScript', 'Vue.js'],
      forksCount: 4,
      avatarUrl: null,
      starCount: 0,
      visibility: 'public',
      openIssuesCount: 48,
      descriptionHtml:
        '<p data-sourcepos="1:1-1:59" dir="auto">Optio et reprehenderit enim doloremque deserunt et commodi.</p>',
      issuesAccessLevel: 'enabled',
      forkingAccessLevel: 'enabled',
      isForked: true,
      accessLevel: {
        integerValue: 30,
      },
    },
    {
      id: 'gid://gitlab/Project/7',
      nameWithNamespace: 'Flightjs / Flight',
      webUrl: 'http://127.0.0.1:3000/flightjs/Flight',
      topics: [],
      forksCount: 0,
      avatarUrl: null,
      starCount: 0,
      visibility: 'private',
      openIssuesCount: 37,
      descriptionHtml:
        '<p data-sourcepos="1:1-1:49" dir="auto">Dolor dicta rerum et ut eius voluptate earum qui.</p>',
      issuesAccessLevel: 'enabled',
      forkingAccessLevel: 'enabled',
      isForked: false,
      accessLevel: {
        integerValue: 20,
      },
    },
    {
      id: 'gid://gitlab/Project/6',
      nameWithNamespace: 'Jashkenas / Underscore',
      webUrl: 'http://127.0.0.1:3000/jashkenas/Underscore',
      topics: [],
      forksCount: 0,
      avatarUrl: null,
      starCount: 0,
      visibility: 'private',
      openIssuesCount: 34,
      descriptionHtml:
        '<p data-sourcepos="1:1-1:52" dir="auto">Incidunt est aliquam autem nihil eveniet quis autem.</p>',
      issuesAccessLevel: 'enabled',
      forkingAccessLevel: 'enabled',
      isForked: false,
      accessLevel: {
        integerValue: 40,
      },
    },
    {
      id: 'gid://gitlab/Project/5',
      nameWithNamespace: 'Commit451 / Lab Coat',
      webUrl: 'http://127.0.0.1:3000/Commit451/lab-coat',
      topics: [],
      forksCount: 0,
      avatarUrl: null,
      starCount: 0,
      visibility: 'internal',
      openIssuesCount: 49,
      descriptionHtml:
        '<p data-sourcepos="1:1-1:34" dir="auto">Sint eos dolorem impedit rerum et.</p>',
      issuesAccessLevel: 'enabled',
      forkingAccessLevel: 'enabled',
      isForked: false,
      accessLevel: {
        integerValue: 10,
      },
    },
    {
      id: 'gid://gitlab/Project/1',
      nameWithNamespace: 'Toolbox / Gitlab Smoke Tests',
      webUrl: 'http://127.0.0.1:3000/toolbox/gitlab-smoke-tests',
      topics: [],
      forksCount: 0,
      avatarUrl: null,
      starCount: 0,
      visibility: 'internal',
      openIssuesCount: 34,
      descriptionHtml:
        '<p data-sourcepos="1:1-1:40" dir="auto">Veritatis error laboriosam libero autem.</p>',
      issuesAccessLevel: 'enabled',
      forkingAccessLevel: 'enabled',
      isForked: false,
      accessLevel: {
        integerValue: 30,
      },
    },
  ],
};

export const organizationGroups = {
  nodes: [
    {
      id: 'gid://gitlab/Group/29',
      fullName: 'Commit451',
      parent: null,
      webUrl: 'http://127.0.0.1:3000/groups/Commit451',
      descriptionHtml:
        '<p data-sourcepos="1:1-1:52" dir="auto">Autem praesentium vel ut ratione itaque ullam culpa.</p>',
      avatarUrl: null,
      descendantGroupsCount: 0,
      projectsCount: 3,
      groupMembersCount: 2,
      visibility: 'public',
      accessLevel: {
        integerValue: 30,
      },
    },
    {
      id: 'gid://gitlab/Group/33',
      fullName: 'Flightjs',
      parent: null,
      webUrl: 'http://127.0.0.1:3000/groups/flightjs',
      descriptionHtml:
        '<p data-sourcepos="1:1-1:60" dir="auto">Ipsa reiciendis deleniti officiis illum nostrum quo aliquam.</p>',
      avatarUrl: null,
      descendantGroupsCount: 4,
      projectsCount: 3,
      groupMembersCount: 1,
      visibility: 'private',
      accessLevel: {
        integerValue: 20,
      },
    },
    {
      id: 'gid://gitlab/Group/24',
      fullName: 'Gitlab Org',
      parent: null,
      webUrl: 'http://127.0.0.1:3000/groups/gitlab-org',
      descriptionHtml:
        '<p data-sourcepos="1:1-1:64" dir="auto">Dolorem dolorem omnis impedit cupiditate pariatur officia velit.</p>',
      avatarUrl: null,
      descendantGroupsCount: 1,
      projectsCount: 1,
      groupMembersCount: 2,
      visibility: 'internal',
      accessLevel: {
        integerValue: 10,
      },
    },
    {
      id: 'gid://gitlab/Group/27',
      fullName: 'Gnuwget',
      parent: null,
      webUrl: 'http://127.0.0.1:3000/groups/gnuwgetf',
      descriptionHtml:
        '<p data-sourcepos="1:1-1:47" dir="auto">Culpa soluta aut eius dolores est vel sapiente.</p>',
      avatarUrl: null,
      descendantGroupsCount: 4,
      projectsCount: 2,
      groupMembersCount: 3,
      visibility: 'public',
      accessLevel: {
        integerValue: 40,
      },
    },
    {
      id: 'gid://gitlab/Group/31',
      fullName: 'Jashkenas',
      parent: null,
      webUrl: 'http://127.0.0.1:3000/groups/jashkenas',
      descriptionHtml: '<p data-sourcepos="1:1-1:25" dir="auto">Ut ut id aliquid nostrum.</p>',
      avatarUrl: null,
      descendantGroupsCount: 3,
      projectsCount: 3,
      groupMembersCount: 10,
      visibility: 'private',
      accessLevel: {
        integerValue: 10,
      },
    },
    {
      id: 'gid://gitlab/Group/22',
      fullName: 'Toolbox',
      parent: null,
      webUrl: 'http://127.0.0.1:3000/groups/toolbox',
      descriptionHtml:
        '<p data-sourcepos="1:1-1:46" dir="auto">Quo voluptatem magnam facere voluptates alias.</p>',
      avatarUrl: null,
      descendantGroupsCount: 2,
      projectsCount: 3,
      groupMembersCount: 40,
      visibility: 'internal',
      accessLevel: {
        integerValue: 30,
      },
    },
    {
      id: 'gid://gitlab/Group/35',
      fullName: 'Twitter',
      parent: null,
      webUrl: 'http://127.0.0.1:3000/groups/twitter',
      descriptionHtml:
        '<p data-sourcepos="1:1-1:40" dir="auto">Quae nulla consequatur assumenda id quo.</p>',
      avatarUrl: null,
      descendantGroupsCount: 20,
      projectsCount: 30,
      groupMembersCount: 100,
      visibility: 'public',
      accessLevel: {
        integerValue: 40,
      },
    },
    {
      id: 'gid://gitlab/Group/73',
      fullName: 'test',
      parent: null,
      webUrl: 'http://127.0.0.1:3000/groups/test',
      descriptionHtml: '',
      avatarUrl: null,
      descendantGroupsCount: 1,
      projectsCount: 1,
      groupMembersCount: 1,
      visibility: 'private',
      accessLevel: {
        integerValue: 30,
      },
    },
    {
      id: 'gid://gitlab/Group/74',
      fullName: 'Twitter / test subgroup',
      parent: {
        id: 'gid://gitlab/Group/35',
      },
      webUrl: 'http://127.0.0.1:3000/groups/twitter/test-subgroup',
      descriptionHtml: '',
      avatarUrl: null,
      descendantGroupsCount: 4,
      projectsCount: 4,
      groupMembersCount: 4,
      visibility: 'internal',
      accessLevel: {
        integerValue: 20,
      },
    },
  ],
};
