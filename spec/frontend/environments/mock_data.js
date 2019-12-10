const environment = {
  name: 'production',
  size: 1,
  state: 'stopped',
  external_url: 'http://external.com',
  environment_type: null,
  last_deployment: {
    id: 66,
    iid: 6,
    sha: '500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
    ref: {
      name: 'master',
      ref_url: 'root/ci-folders/tree/master',
    },
    tag: true,
    'last?': true,
    user: {
      name: 'Administrator',
      username: 'root',
      id: 1,
      state: 'active',
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      web_url: 'http://localhost:3000/root',
    },
    commit: {
      id: '500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
      short_id: '500aabcb',
      title: 'Update .gitlab-ci.yml',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      created_at: '2016-11-07T18:28:13.000+00:00',
      message: 'Update .gitlab-ci.yml',
      author: {
        name: 'Administrator',
        username: 'root',
        id: 1,
        state: 'active',
        avatar_url:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
        web_url: 'http://localhost:3000/root',
      },
      commit_path: '/root/ci-folders/tree/500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
    },
    deployable: {
      id: 1279,
      name: 'deploy',
      build_path: '/root/ci-folders/builds/1279',
      retry_path: '/root/ci-folders/builds/1279/retry',
      created_at: '2016-11-29T18:11:58.430Z',
      updated_at: '2016-11-29T18:11:58.430Z',
    },
    manual_actions: [
      {
        name: 'action',
        play_path: '/play',
      },
    ],
    deployed_at: '2016-11-29T18:11:58.430Z',
  },
  has_stop_action: true,
  environment_path: 'root/ci-folders/environments/31',
  log_path: 'root/ci-folders/environments/31/logs',
  created_at: '2016-11-07T11:11:16.525Z',
  updated_at: '2016-11-10T15:55:58.778Z',
};

const folder = {
  name: 'review',
  folderName: 'review',
  size: 3,
  isFolder: true,
  environment_path: 'url',
  log_path: 'url',
  latest: {
    environment_path: 'url',
  },
};

const tableData = {
  name: {
    title: 'Environment',
    spacing: 'section-15',
  },
  deploy: {
    title: 'Deployment',
    spacing: 'section-10',
  },
  build: {
    title: 'Job',
    spacing: 'section-15',
  },
  commit: {
    title: 'Commit',
    spacing: 'section-20',
  },
  date: {
    title: 'Updated',
    spacing: 'section-10',
  },
  actions: {
    spacing: 'section-25',
  },
};

export { environment, folder, tableData };
