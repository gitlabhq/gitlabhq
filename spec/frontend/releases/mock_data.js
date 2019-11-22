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
  evidence_sha: 'fb3a125fd69a0e5048ebfb0ba43eb32ce4911520dd8d',
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
  assets: {
    count: 5,
    evidence_file_path:
      'https://20592.qa-tunnel.gitlab.info/root/test-deployments/-/releases/v1.1.2/evidence.json',
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
        external: true,
      },
      {
        id: 2,
        name: 'my second link',
        url:
          'https://gitlab.com/gitlab-org/gitlab-foss/-/jobs/artifacts/v11.6.0-rc4/download?job=rspec-mysql+41%2F50',
        external: false,
      },
    ],
  },
  _links: {
    edit_url: 'http://0.0.0.0:3001/root/release-test/-/releases/v0.3/edit',
  },
};
