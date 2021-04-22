const devProps = {
  id: 7,
  name: 'DEV',
  state: 'available',
  external_url: null,
  environment_type: null,
  last_deployment: null,
  has_stop_action: false,
  environment_path: '/root/review-app/environments/7',
  stop_path: '/root/review-app/environments/7/stop',
  created_at: '2017-01-31T10:53:46.894Z',
  updated_at: '2017-01-31T10:53:46.894Z',
};

const buildProps = {
  id: 12,
  name: 'build/update-README',
  state: 'available',
  external_url: null,
  environment_type: 'build',
  last_deployment: null,
  has_stop_action: false,
  environment_path: '/root/review-app/environments/12',
  stop_path: '/root/review-app/environments/12/stop',
  created_at: '2017-02-01T19:42:18.400Z',
  updated_at: '2017-02-01T19:42:18.400Z',
};

const deployBoardMockData = {
  instances: [
    { status: 'finished', tooltip: 'tanuki-2334 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2335 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2336 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2337 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2338 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2339 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2340 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2334 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2335 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2336 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2337 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2338 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2339 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2340 Finished', pod_name: 'production-tanuki-1' },
    { status: 'deploying', tooltip: 'tanuki-2341 Deploying', pod_name: 'production-tanuki-1' },
    { status: 'deploying', tooltip: 'tanuki-2342 Deploying', pod_name: 'production-tanuki-1' },
    { status: 'deploying', tooltip: 'tanuki-2343 Deploying', pod_name: 'production-tanuki-1' },
    { status: 'failed', tooltip: 'tanuki-2344 Failed', pod_name: 'production-tanuki-1' },
    { status: 'ready', tooltip: 'tanuki-2345 Ready', pod_name: 'production-tanuki-1' },
    { status: 'ready', tooltip: 'tanuki-2346 Ready', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2348 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2349 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2350 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2353 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'waiting', tooltip: 'tanuki-2354 Waiting', pod_name: 'production-tanuki-1' },
    { status: 'waiting', tooltip: 'tanuki-2355 Waiting', pod_name: 'production-tanuki-1' },
    { status: 'waiting', tooltip: 'tanuki-2356 Waiting', pod_name: 'production-tanuki-1' },
  ],
  abort_url: 'url',
  rollback_url: 'url',
  completion: 100,
  status: 'found',
  canary_ingress: {
    canary_weight: 50,
  },
};

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
      name: 'main',
      ref_url: 'root/ci-folders/tree/main',
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
  upcoming_deployment: {
    id: 82,
    iid: 27,
    sha: '1132df044b73943943c949e7ac2c2f120a89bf59',
    ref: {
      name: 'main',
      ref_path: '/root/environment-test/-/tree/main',
    },
    status: 'running',
    created_at: '2020-12-04T19:57:49.514Z',
    deployed_at: null,
    tag: false,
    'last?': false,
    user: {
      id: 1,
      name: 'Upcoming Name',
      username: 'upcoming-username',
      state: 'active',
      avatar_url: 'http://0.0.0.0:3000/uploads/-/system/user/avatar/2/avatar.png',
      web_url: 'http://0.0.0.0:3000/upcoming-username',
      show_status: false,
      path: '/upcoming-username',
    },
    deployable: {
      id: 1310,
      name: 'deploy_to_development',
      started: '2020-12-04T19:58:10.806Z',
      archived: false,
      build_path: '/root/environment-test/-/jobs/892',
      cancel_path:
        '/root/environment-test/-/jobs/892/cancel?continue%5Bto%5D=%2Froot%2Fenvironment-test%2F-%2Fjobs%2F892',
      playable: false,
      scheduled: false,
      created_at: '2020-12-04T19:57:49.455Z',
      updated_at: '2020-12-04T19:58:10.809Z',
      status: {
        icon: 'status_running',
        text: 'running',
        label: 'running',
        group: 'running',
        tooltip: 'running',
        has_details: true,
        details_path: '/root/environment-test/-/jobs/892',
        illustration: {
          image:
            '/assets/illustrations/skipped-job_empty-29a8a37d8a61d1b6f68cf3484f9024e53cd6eb95e28eae3554f8011a1146bf27.svg',
          size: 'svg-430',
          title: 'This job does not have a trace.',
        },
        favicon:
          '/assets/ci_favicons/favicon_status_running-9c635b2419a8e1ec991c993061b89cc5aefc0743bb238ecd0c381e7741a70e8c.png',
        action: {
          icon: 'cancel',
          title: 'Cancel',
          path: '/root/environment-test/-/jobs/892/cancel',
          method: 'post',
          button_title: 'Cancel this job',
        },
      },
    },
    commit: {
      id: '1132df044b73943943c949e7ac2c2f120a89bf59',
      short_id: '1132df04',
      created_at: '2020-12-01T15:46:26.000-05:00',
      parent_ids: ['e0808dee2a5877563ec140e65d8b41908f90098c'],
      title: 'Update .gitlab-ci.yml',
      message: 'Update .gitlab-ci.yml',
      author_name: 'Upcoming Name',
      author_email: 'admin@example.com',
      authored_date: '2020-12-01T15:46:26.000-05:00',
      committer_name: 'Upcoming Name',
      committer_email: 'admin@example.com',
      committed_date: '2020-12-01T15:46:26.000-05:00',
      web_url:
        'http://0.0.0.0:3000/root/environment-test/-/commit/1132df044b73943943c949e7ac2c2f120a89bf59',
      author: {
        id: 1,
        name: 'Upcoming Name',
        username: 'upcoming-username',
        state: 'active',
        avatar_url: 'http://0.0.0.0:3000/uploads/-/system/user/avatar/2/avatar.png',
        web_url: 'http://0.0.0.0:3000/upcoming-username',
        show_status: false,
        path: '/upcoming-username',
      },
      author_gravatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      commit_url:
        'http://0.0.0.0:3000/root/environment-test/-/commit/1132df044b73943943c949e7ac2c2f120a89bf59',
      commit_path: '/root/environment-test/-/commit/1132df044b73943943c949e7ac2c2f120a89bf59',
    },
  },
  has_stop_action: true,
  environment_path: 'root/ci-folders/environments/31',
  log_path: 'root/ci-folders/environments/31/logs',
  created_at: '2016-11-07T11:11:16.525Z',
  updated_at: '2016-11-10T15:55:58.778Z',
  auto_stop_at: null,
};

const environmentsList = [
  {
    size: 1,
    ...devProps,
  },
  {
    folderName: 'build',
    size: 5,
    ...buildProps,
  },
];

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

const serverData = [
  {
    name: 'DEV',
    size: 1,
    latest: {
      ...devProps,
    },
  },
  {
    name: 'build',
    size: 5,
    latest: {
      ...buildProps,
    },
  },
];

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
  upcoming: {
    title: 'Upcoming',
    mobileTitle: 'Upcoming deployment',
    spacing: 'section-10',
  },
  autoStop: {
    title: 'Auto stop in',
    spacing: 'section-5',
  },
  actions: {
    spacing: 'section-25',
  },
};

export { environment, environmentsList, folder, serverData, tableData, deployBoardMockData };
