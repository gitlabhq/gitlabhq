export const milestones = [
  {
    id: 50,
    iid: 2,
    project_id: 18,
    title: '13.6',
    description: 'The 13.6 milestone!',
    state: 'active',
    created_at: '2019-08-27T17:22:38.280Z',
    updated_at: '2019-08-27T17:22:38.280Z',
    due_date: '2019-09-19',
    start_date: '2019-08-31',
    web_url: 'http://0.0.0.0:3001/root/release-test/-/milestones/2',
    issue_stats: {
      total: 33,
      closed: 19,
    },
  },
  {
    id: 49,
    iid: 1,
    project_id: 18,
    title: '13.5',
    description: 'The 13.5 milestone!',
    state: 'active',
    created_at: '2019-08-26T17:55:48.643Z',
    updated_at: '2019-08-26T17:55:48.643Z',
    due_date: '2019-10-11',
    start_date: '2019-08-19',
    web_url: 'http://0.0.0.0:3001/root/release-test/-/milestones/1',
    issue_stats: {
      total: 21,
      closed: 3,
    },
  },
];

export const release = {
  name: 'New release',
  tag_name: 'v0.3',
  tag_path: '/root/release-test/-/tags/v0.3',
  description: 'A super nice release!',
  description_html: '<p data-sourcepos="1:1-1:21" dir="auto">A super nice release!</p>',
  created_at: '2019-08-26T17:54:04.952Z',
  released_at: '2019-08-26T17:54:04.807Z',
  author: {
    id: 1,
    name: 'Administrator',
    username: 'root',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    web_url: 'http://0.0.0.0:3001/root',
  },
  commit: {
    id: 'c22b0728d1b465f82898c884d32b01aa642f96c1',
    short_id: 'c22b0728',
    created_at: '2019-08-26T17:47:07.000Z',
    parent_ids: [],
    title: 'Initial commit',
    message: 'Initial commit',
    author_name: 'Administrator',
    author_email: 'admin@example.com',
    authored_date: '2019-08-26T17:47:07.000Z',
    committer_name: 'Administrator',
    committer_email: 'admin@example.com',
    committed_date: '2019-08-26T17:47:07.000Z',
  },
  commit_path: '/root/release-test/commit/c22b0728d1b465f82898c884d32b01aa642f96c1',
  upcoming_release: false,
  milestones,
  evidences: [
    {
      filepath:
        'https://20592.qa-tunnel.gitlab.info/root/test-deployments/-/releases/v1.1.2/evidences/1.json',
      sha: 'fb3a125fd69a0e5048ebfb0ba43eb32ce4911520dd8d',
      collected_at: '2018-10-19 15:43:20 +0200',
    },
    {
      filepath:
        'https://20592.qa-tunnel.gitlab.info/root/test-deployments/-/releases/v1.1.2/evidences/2.json',
      sha: '6ebd17a66e6a861175735416e49cf677678029805712dd71bb805c609e2d9108',
      collected_at: '2018-10-19 15:43:20 +0200',
    },
    {
      filepath:
        'https://20592.qa-tunnel.gitlab.info/root/test-deployments/-/releases/v1.1.2/evidences/3.json',
      sha: '2f65beaf275c3cb4b4e24fb01d481cc475d69c957830833f15338384816b5cba',
      collected_at: '2018-10-19 15:43:20 +0200',
    },
  ],
  assets: {
    count: 5,
    sources: [
      {
        format: 'zip',
        url: 'http://0.0.0.0:3001/root/release-test/-/archive/v0.3/release-test-v0.3.zip',
      },
      {
        format: 'tar.gz',
        url: 'http://0.0.0.0:3001/root/release-test/-/archive/v0.3/release-test-v0.3.tar.gz',
      },
      {
        format: 'tar.bz2',
        url: 'http://0.0.0.0:3001/root/release-test/-/archive/v0.3/release-test-v0.3.tar.bz2',
      },
      {
        format: 'tar',
        url: 'http://0.0.0.0:3001/root/release-test/-/archive/v0.3/release-test-v0.3.tar',
      },
    ],
    links: [
      {
        id: 1,
        name: 'my link',
        url: 'https://google.com',
        direct_asset_url: 'https://redirected.google.com',
        external: true,
      },
      {
        id: 2,
        name: 'my second link',
        url:
          'https://gitlab.com/gitlab-org/gitlab-foss/-/jobs/artifacts/v11.6.0-rc4/download?job=rspec-mysql+41%2F50',
        direct_asset_url: 'https://redirected.google.com',
        external: false,
      },
    ],
  },
  _links: {
    self: 'http://0.0.0.0:3001/root/release-test/-/releases/v0.3',
    edit_url: 'http://0.0.0.0:3001/root/release-test/-/releases/v0.3/edit',
  },
};

export const pageInfoHeadersWithoutPagination = {
  'X-NEXT-PAGE': '',
  'X-PAGE': '1',
  'X-PER-PAGE': '20',
  'X-PREV-PAGE': '',
  'X-TOTAL': '19',
  'X-TOTAL-PAGES': '1',
};

export const pageInfoHeadersWithPagination = {
  'X-NEXT-PAGE': '2',
  'X-PAGE': '1',
  'X-PER-PAGE': '20',
  'X-PREV-PAGE': '',
  'X-TOTAL': '21',
  'X-TOTAL-PAGES': '2',
};

export const release2 = {
  name: 'Bionic Beaver',
  tag_name: '18.04',
  description: '## changelog\n\n* line 1\n* line2',
  description_html: '<div><h2>changelog</h2><ul><li>line1</li<li>line 2</li></ul></div>',
  author_name: 'Release bot',
  author_email: 'release-bot@example.com',
  created_at: '2012-05-28T05:00:00-07:00',
  commit: {
    id: '2695effb5807a22ff3d138d593fd856244e155e7',
    short_id: '2695effb',
    title: 'Initial commit',
    created_at: '2017-07-26T11:08:53.000+02:00',
    parent_ids: ['2a4b78934375d7f53875269ffd4f45fd83a84ebe'],
    message: 'Initial commit',
    author: {
      avatar_url: 'uploads/-/system/user/avatar/johndoe/avatar.png',
      id: 482476,
      name: 'John Doe',
      path: '/johndoe',
      state: 'active',
      status_tooltip_html: null,
      username: 'johndoe',
      web_url: 'https://gitlab.com/johndoe',
    },
    authored_date: '2012-05-28T04:42:42-07:00',
    committer_name: 'Jack Smith',
    committer_email: 'jack@example.com',
    committed_date: '2012-05-28T04:42:42-07:00',
  },
  assets: {
    count: 6,
    sources: [
      {
        format: 'zip',
        url: 'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.zip',
      },
      {
        format: 'tar.gz',
        url:
          'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar.gz',
      },
      {
        format: 'tar.bz2',
        url:
          'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar.bz2',
      },
      {
        format: 'tar',
        url: 'https://gitlab.com/gitlab-org/gitlab-foss/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar',
      },
    ],
    links: [
      {
        name: 'release-18.04.dmg',
        url: 'https://my-external-hosting.example.com/scrambled-url/',
        external: true,
      },
      {
        name: 'binary-linux-amd64',
        url:
          'https://gitlab.com/gitlab-org/gitlab-foss/-/jobs/artifacts/v11.6.0-rc4/download?job=rspec-mysql+41%2F50',
        external: false,
      },
    ],
  },
};

export const releases = [release, release2];
