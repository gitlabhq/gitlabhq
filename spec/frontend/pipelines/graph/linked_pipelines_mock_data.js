export default {
  id: 23211253,
  user: {
    id: 3585,
    name: 'Achilleas Pipinellis',
    username: 'axil',
    state: 'active',
    avatar_url: 'https://assets.gitlab-static.net/uploads/-/system/user/avatar/3585/avatar.png',
    web_url: 'https://gitlab.com/axil',
    status_tooltip_html:
      '\u003cspan class="user-status-emoji has-tooltip" title="I like pizza" data-html="true" data-placement="top"\u003e\u003cgl-emoji title="slice of pizza" data-name="pizza" data-unicode-version="6.0"\u003e🍕\u003c/gl-emoji\u003e\u003c/span\u003e',
    path: '/axil',
  },
  active: false,
  coverage: null,
  source: 'push',
  source_job: {
    name: 'trigger_job',
  },
  created_at: '2018-06-05T11:31:30.452Z',
  updated_at: '2018-10-31T16:35:31.305Z',
  path: '/gitlab-org/gitlab-runner/pipelines/23211253',
  flags: {
    latest: false,
    stuck: false,
    auto_devops: false,
    merge_request: false,
    yaml_errors: false,
    retryable: false,
    cancelable: false,
    failure_reason: false,
  },
  details: {
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/gitlab-org/gitlab-runner/pipelines/23211253',
      illustration: null,
      favicon:
        'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    duration: 53,
    finished_at: '2018-10-31T16:35:31.299Z',
    stages: [
      {
        name: 'prebuild',
        title: 'prebuild: passed',
        groups: [
          {
            name: 'review-docs-deploy',
            size: 1,
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'manual play action',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-runner/-/jobs/72469032',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                size: 'svg-394',
                title: 'This job requires a manual action',
                content:
                  'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'play',
                title: 'Play',
                path: '/gitlab-org/gitlab-runner/-/jobs/72469032/play',
                method: 'post',
                button_title: 'Trigger this manual action',
              },
            },
            jobs: [
              {
                id: 72469032,
                name: 'review-docs-deploy',
                started: '2018-10-31T16:34:58.778Z',
                archived: false,
                build_path: '/gitlab-org/gitlab-runner/-/jobs/72469032',
                retry_path: '/gitlab-org/gitlab-runner/-/jobs/72469032/retry',
                play_path: '/gitlab-org/gitlab-runner/-/jobs/72469032/play',
                playable: true,
                scheduled: false,
                created_at: '2018-06-05T11:31:30.495Z',
                updated_at: '2018-10-31T16:35:31.251Z',
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'manual play action',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-runner/-/jobs/72469032',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-org/gitlab-runner/-/jobs/72469032/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
              },
            ],
          },
        ],
        status: {
          icon: 'status_success',
          text: 'passed',
          label: 'passed',
          group: 'success',
          tooltip: 'passed',
          has_details: true,
          details_path: '/gitlab-org/gitlab-runner/pipelines/23211253#prebuild',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
        },
        path: '/gitlab-org/gitlab-runner/pipelines/23211253#prebuild',
        dropdown_path: '/gitlab-org/gitlab-runner/pipelines/23211253/stage.json?stage=prebuild',
      },
      {
        name: 'test',
        title: 'test: passed',
        groups: [
          {
            name: 'docs check links',
            size: 1,
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-runner/-/jobs/72469033',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                size: 'svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-runner/-/jobs/72469033/retry',
                method: 'post',
                button_title: 'Retry this job',
              },
            },
            jobs: [
              {
                id: 72469033,
                name: 'docs check links',
                started: '2018-06-05T11:31:33.240Z',
                archived: false,
                build_path: '/gitlab-org/gitlab-runner/-/jobs/72469033',
                retry_path: '/gitlab-org/gitlab-runner/-/jobs/72469033/retry',
                playable: false,
                scheduled: false,
                created_at: '2018-06-05T11:31:30.627Z',
                updated_at: '2018-06-05T11:31:54.363Z',
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'passed',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-runner/-/jobs/72469033',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job does not have a trace.',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                  action: {
                    icon: 'retry',
                    title: 'Retry',
                    path: '/gitlab-org/gitlab-runner/-/jobs/72469033/retry',
                    method: 'post',
                    button_title: 'Retry this job',
                  },
                },
              },
            ],
          },
        ],
        status: {
          icon: 'status_success',
          text: 'passed',
          label: 'passed',
          group: 'success',
          tooltip: 'passed',
          has_details: true,
          details_path: '/gitlab-org/gitlab-runner/pipelines/23211253#test',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
        },
        path: '/gitlab-org/gitlab-runner/pipelines/23211253#test',
        dropdown_path: '/gitlab-org/gitlab-runner/pipelines/23211253/stage.json?stage=test',
      },
      {
        name: 'cleanup',
        title: 'cleanup: skipped',
        groups: [
          {
            name: 'review-docs-cleanup',
            size: 1,
            status: {
              icon: 'status_manual',
              text: 'manual',
              label: 'manual stop action',
              group: 'manual',
              tooltip: 'manual action',
              has_details: true,
              details_path: '/gitlab-org/gitlab-runner/-/jobs/72469034',
              illustration: {
                image:
                  'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                size: 'svg-394',
                title: 'This job requires a manual action',
                content:
                  'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
              },
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
              action: {
                icon: 'stop',
                title: 'Stop',
                path: '/gitlab-org/gitlab-runner/-/jobs/72469034/play',
                method: 'post',
                button_title: 'Stop this environment',
              },
            },
            jobs: [
              {
                id: 72469034,
                name: 'review-docs-cleanup',
                started: null,
                archived: false,
                build_path: '/gitlab-org/gitlab-runner/-/jobs/72469034',
                play_path: '/gitlab-org/gitlab-runner/-/jobs/72469034/play',
                playable: true,
                scheduled: false,
                created_at: '2018-06-05T11:31:30.760Z',
                updated_at: '2018-06-05T11:31:56.037Z',
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual stop action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-org/gitlab-runner/-/jobs/72469034',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'stop',
                    title: 'Stop',
                    path: '/gitlab-org/gitlab-runner/-/jobs/72469034/play',
                    method: 'post',
                    button_title: 'Stop this environment',
                  },
                },
              },
            ],
          },
        ],
        status: {
          icon: 'status_skipped',
          text: 'skipped',
          label: 'skipped',
          group: 'skipped',
          tooltip: 'skipped',
          has_details: true,
          details_path: '/gitlab-org/gitlab-runner/pipelines/23211253#cleanup',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
        },
        path: '/gitlab-org/gitlab-runner/pipelines/23211253#cleanup',
        dropdown_path: '/gitlab-org/gitlab-runner/pipelines/23211253/stage.json?stage=cleanup',
      },
    ],
    artifacts: [],
    manual_actions: [
      {
        name: 'review-docs-cleanup',
        path: '/gitlab-org/gitlab-runner/-/jobs/72469034/play',
        playable: true,
        scheduled: false,
      },
      {
        name: 'review-docs-deploy',
        path: '/gitlab-org/gitlab-runner/-/jobs/72469032/play',
        playable: true,
        scheduled: false,
      },
    ],
    scheduled_actions: [],
  },
  ref: {
    name: 'docs/add-development-guide-to-readme',
    path: '/gitlab-org/gitlab-runner/commits/docs/add-development-guide-to-readme',
    tag: false,
    branch: true,
    merge_request: false,
  },
  commit: {
    id: '8083eb0a920572214d0dccedd7981f05d535ad46',
    short_id: '8083eb0a',
    title: 'Add link to development guide in readme',
    created_at: '2018-06-05T11:30:48.000Z',
    parent_ids: ['1d7cf79b5a1a2121b9474ac20d61c1b8f621289d'],
    message:
      'Add link to development guide in readme\n\nCloses https://gitlab.com/gitlab-org/gitlab-runner/issues/3122\n',
    author_name: 'Achilleas Pipinellis',
    author_email: 'axil@gitlab.com',
    authored_date: '2018-06-05T11:30:48.000Z',
    committer_name: 'Achilleas Pipinellis',
    committer_email: 'axil@gitlab.com',
    committed_date: '2018-06-05T11:30:48.000Z',
    author: {
      id: 3585,
      name: 'Achilleas Pipinellis',
      username: 'axil',
      state: 'active',
      avatar_url: 'https://assets.gitlab-static.net/uploads/-/system/user/avatar/3585/avatar.png',
      web_url: 'https://gitlab.com/axil',
      status_tooltip_html: null,
      path: '/axil',
    },
    author_gravatar_url:
      'https://secure.gravatar.com/avatar/1d37af00eec153a8333a4ce18e9aea41?s=80\u0026d=identicon',
    commit_url:
      'https://gitlab.com/gitlab-org/gitlab-runner/commit/8083eb0a920572214d0dccedd7981f05d535ad46',
    commit_path: '/gitlab-org/gitlab-runner/commit/8083eb0a920572214d0dccedd7981f05d535ad46',
  },
  project: { id: 20 },
  triggered_by: {
    id: 12,
    user: {
      id: 376774,
      name: 'Alessio Caiazza',
      username: 'nolith',
      state: 'active',
      avatar_url: 'https://assets.gitlab-static.net/uploads/-/system/user/avatar/376774/avatar.png',
      web_url: 'https://gitlab.com/nolith',
      status_tooltip_html: null,
      path: '/nolith',
    },
    active: false,
    coverage: null,
    source: 'pipeline',
    source_job: {
      name: 'trigger_job',
    },
    path: '/gitlab-com/gitlab-docs/pipelines/34993051',
    details: {
      status: {
        icon: 'status_failed',
        text: 'failed',
        label: 'failed',
        group: 'failed',
        tooltip: 'failed',
        has_details: true,
        details_path: '/gitlab-com/gitlab-docs/pipelines/34993051',
        illustration: null,
        favicon:
          'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
      },
      duration: 118,
      finished_at: '2018-10-31T16:41:40.615Z',
      stages: [
        {
          name: 'build-images',
          title: 'build-images: skipped',
          groups: [
            {
              name: 'image:bootstrap',
              size: 1,
              status: {
                icon: 'status_manual',
                text: 'manual',
                label: 'manual play action',
                group: 'manual',
                tooltip: 'manual action',
                has_details: true,
                details_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                illustration: {
                  image:
                    'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                  size: 'svg-394',
                  title: 'This job requires a manual action',
                  content:
                    'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                },
                favicon:
                  'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                action: {
                  icon: 'play',
                  title: 'Play',
                  path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                  method: 'post',
                  button_title: 'Trigger this manual action',
                },
              },
              jobs: [
                {
                  id: 11421321982853,
                  name: 'image:bootstrap',
                  started: null,
                  archived: false,
                  build_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                  play_path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                  playable: true,
                  scheduled: false,
                  created_at: '2018-10-31T16:35:23.704Z',
                  updated_at: '2018-10-31T16:35:24.118Z',
                  status: {
                    icon: 'status_manual',
                    text: 'manual',
                    label: 'manual play action',
                    group: 'manual',
                    tooltip: 'manual action',
                    has_details: true,
                    details_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                    illustration: {
                      image:
                        'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                      size: 'svg-394',
                      title: 'This job requires a manual action',
                      content:
                        'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                    },
                    favicon:
                      'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                    action: {
                      icon: 'play',
                      title: 'Play',
                      path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                      method: 'post',
                      button_title: 'Trigger this manual action',
                    },
                  },
                },
              ],
            },
            {
              name: 'image:builder-onbuild',
              size: 1,
              status: {
                icon: 'status_manual',
                text: 'manual',
                label: 'manual play action',
                group: 'manual',
                tooltip: 'manual action',
                has_details: true,
                details_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                illustration: {
                  image:
                    'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                  size: 'svg-394',
                  title: 'This job requires a manual action',
                  content:
                    'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                },
                favicon:
                  'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                action: {
                  icon: 'play',
                  title: 'Play',
                  path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                  method: 'post',
                  button_title: 'Trigger this manual action',
                },
              },
              jobs: [
                {
                  id: 1149822131854,
                  name: 'image:builder-onbuild',
                  started: null,
                  archived: false,
                  build_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                  play_path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                  playable: true,
                  scheduled: false,
                  created_at: '2018-10-31T16:35:23.728Z',
                  updated_at: '2018-10-31T16:35:24.070Z',
                  status: {
                    icon: 'status_manual',
                    text: 'manual',
                    label: 'manual play action',
                    group: 'manual',
                    tooltip: 'manual action',
                    has_details: true,
                    details_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                    illustration: {
                      image:
                        'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                      size: 'svg-394',
                      title: 'This job requires a manual action',
                      content:
                        'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                    },
                    favicon:
                      'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                    action: {
                      icon: 'play',
                      title: 'Play',
                      path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                      method: 'post',
                      button_title: 'Trigger this manual action',
                    },
                  },
                },
              ],
            },
            {
              name: 'image:nginx-onbuild',
              size: 1,
              status: {
                icon: 'status_manual',
                text: 'manual',
                label: 'manual play action',
                group: 'manual',
                tooltip: 'manual action',
                has_details: true,
                details_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                illustration: {
                  image:
                    'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                  size: 'svg-394',
                  title: 'This job requires a manual action',
                  content:
                    'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                },
                favicon:
                  'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                action: {
                  icon: 'play',
                  title: 'Play',
                  path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                  method: 'post',
                  button_title: 'Trigger this manual action',
                },
              },
              jobs: [
                {
                  id: 11498285523424,
                  name: 'image:nginx-onbuild',
                  started: null,
                  archived: false,
                  build_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                  play_path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                  playable: true,
                  scheduled: false,
                  created_at: '2018-10-31T16:35:23.753Z',
                  updated_at: '2018-10-31T16:35:24.033Z',
                  status: {
                    icon: 'status_manual',
                    text: 'manual',
                    label: 'manual play action',
                    group: 'manual',
                    tooltip: 'manual action',
                    has_details: true,
                    details_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                    illustration: {
                      image:
                        'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                      size: 'svg-394',
                      title: 'This job requires a manual action',
                      content:
                        'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                    },
                    favicon:
                      'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                    action: {
                      icon: 'play',
                      title: 'Play',
                      path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                      method: 'post',
                      button_title: 'Trigger this manual action',
                    },
                  },
                },
              ],
            },
          ],
          status: {
            icon: 'status_skipped',
            text: 'skipped',
            label: 'skipped',
            group: 'skipped',
            tooltip: 'skipped',
            has_details: true,
            details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#build-images',
            illustration: null,
            favicon:
              'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
          },
          path: '/gitlab-com/gitlab-docs/pipelines/34993051#build-images',
          dropdown_path: '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=build-images',
        },
        {
          name: 'build',
          title: 'build: failed',
          groups: [
            {
              name: 'compile_dev',
              size: 1,
              status: {
                icon: 'status_failed',
                text: 'failed',
                label: 'failed',
                group: 'failed',
                tooltip: 'failed - (script failure)',
                has_details: true,
                details_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                illustration: {
                  image:
                    'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                  size: 'svg-430',
                  title: 'This job does not have a trace.',
                },
                favicon:
                  'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                action: {
                  icon: 'retry',
                  title: 'Retry',
                  path: '/h5bp/html5-boilerplate/-/jobs/528/retry',
                  method: 'post',
                  button_title: 'Retry this job',
                },
              },
              jobs: [
                {
                  id: 1149846949786,
                  name: 'compile_dev',
                  started: '2018-10-31T16:39:41.598Z',
                  archived: false,
                  build_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                  retry_path: '/gitlab-com/gitlab-docs/-/jobs/114984694/retry',
                  playable: false,
                  scheduled: false,
                  created_at: '2018-10-31T16:39:41.138Z',
                  updated_at: '2018-10-31T16:41:40.072Z',
                  status: {
                    icon: 'status_failed',
                    text: 'failed',
                    label: 'failed',
                    group: 'failed',
                    tooltip: 'failed - (script failure)',
                    has_details: true,
                    details_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                    illustration: {
                      image:
                        'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                      size: 'svg-430',
                      title: 'This job does not have a trace.',
                    },
                    favicon:
                      'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                    action: {
                      icon: 'retry',
                      title: 'Retry',
                      path: '/h5bp/html5-boilerplate/-/jobs/528/retry',
                      method: 'post',
                      button_title: 'Retry this job',
                    },
                  },
                  recoverable: false,
                },
              ],
            },
          ],
          status: {
            icon: 'status_failed',
            text: 'failed',
            label: 'failed',
            group: 'failed',
            tooltip: 'failed',
            has_details: true,
            details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#build',
            illustration: null,
            favicon:
              'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
          },
          path: '/gitlab-com/gitlab-docs/pipelines/34993051#build',
          dropdown_path: '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=build',
        },
        {
          name: 'deploy',
          title: 'deploy: skipped',
          groups: [
            {
              name: 'review',
              size: 1,
              status: {
                icon: 'status_skipped',
                text: 'skipped',
                label: 'skipped',
                group: 'skipped',
                tooltip: 'skipped',
                has_details: true,
                details_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                illustration: {
                  image:
                    'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                  size: 'svg-430',
                  title: 'This job has been skipped',
                },
                favicon:
                  'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
              },
              jobs: [
                {
                  id: 11498282342357,
                  name: 'review',
                  started: null,
                  archived: false,
                  build_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                  playable: false,
                  scheduled: false,
                  created_at: '2018-10-31T16:35:23.805Z',
                  updated_at: '2018-10-31T16:41:40.569Z',
                  status: {
                    icon: 'status_skipped',
                    text: 'skipped',
                    label: 'skipped',
                    group: 'skipped',
                    tooltip: 'skipped',
                    has_details: true,
                    details_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                    illustration: {
                      image:
                        'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                      size: 'svg-430',
                      title: 'This job has been skipped',
                    },
                    favicon:
                      'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                  },
                },
              ],
            },
            {
              name: 'review_stop',
              size: 1,
              status: {
                icon: 'status_skipped',
                text: 'skipped',
                label: 'skipped',
                group: 'skipped',
                tooltip: 'skipped',
                has_details: true,
                details_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                illustration: {
                  image:
                    'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                  size: 'svg-430',
                  title: 'This job has been skipped',
                },
                favicon:
                  'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
              },
              jobs: [
                {
                  id: 114982858,
                  name: 'review_stop',
                  started: null,
                  archived: false,
                  build_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                  playable: false,
                  scheduled: false,
                  created_at: '2018-10-31T16:35:23.840Z',
                  updated_at: '2018-10-31T16:41:40.480Z',
                  status: {
                    icon: 'status_skipped',
                    text: 'skipped',
                    label: 'skipped',
                    group: 'skipped',
                    tooltip: 'skipped',
                    has_details: true,
                    details_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                    illustration: {
                      image:
                        'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                      size: 'svg-430',
                      title: 'This job has been skipped',
                    },
                    favicon:
                      'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                  },
                },
              ],
            },
          ],
          status: {
            icon: 'status_skipped',
            text: 'skipped',
            label: 'skipped',
            group: 'skipped',
            tooltip: 'skipped',
            has_details: true,
            details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#deploy',
            illustration: null,
            favicon:
              'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
          },
          path: '/gitlab-com/gitlab-docs/pipelines/34993051#deploy',
          dropdown_path: '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=deploy',
        },
      ],
      artifacts: [],
      manual_actions: [
        {
          name: 'image:bootstrap',
          path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
          playable: true,
          scheduled: false,
        },
        {
          name: 'image:builder-onbuild',
          path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
          playable: true,
          scheduled: false,
        },
        {
          name: 'image:nginx-onbuild',
          path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
          playable: true,
          scheduled: false,
        },
        {
          name: 'review_stop',
          path: '/gitlab-com/gitlab-docs/-/jobs/114982858/play',
          playable: false,
          scheduled: false,
        },
      ],
      scheduled_actions: [],
    },
    project: {
      id: 20,
      name: 'Test',
      full_path: '/gitlab-com/gitlab-docs',
      full_name: 'GitLab.com / GitLab Docs',
    },
    triggered_by: {
      id: 349932310342451,
      user: {
        id: 376774,
        name: 'Alessio Caiazza',
        username: 'nolith',
        state: 'active',
        avatar_url:
          'https://assets.gitlab-static.net/uploads/-/system/user/avatar/376774/avatar.png',
        web_url: 'https://gitlab.com/nolith',
        status_tooltip_html: null,
        path: '/nolith',
      },
      active: false,
      coverage: null,
      source: 'pipeline',
      source_job: {
        name: 'trigger_job',
      },
      path: '/gitlab-com/gitlab-docs/pipelines/34993051',
      details: {
        status: {
          icon: 'status_failed',
          text: 'failed',
          label: 'failed',
          group: 'failed',
          tooltip: 'failed',
          has_details: true,
          details_path: '/gitlab-com/gitlab-docs/pipelines/34993051',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
        },
        duration: 118,
        finished_at: '2018-10-31T16:41:40.615Z',
        stages: [
          {
            name: 'build-images',
            title: 'build-images: skipped',
            groups: [
              {
                name: 'image:bootstrap',
                size: 1,
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
                jobs: [
                  {
                    id: 11421321982853,
                    name: 'image:bootstrap',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                    play_path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                    playable: true,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.704Z',
                    updated_at: '2018-10-31T16:35:24.118Z',
                    status: {
                      icon: 'status_manual',
                      text: 'manual',
                      label: 'manual play action',
                      group: 'manual',
                      tooltip: 'manual action',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                  },
                ],
              },
              {
                name: 'image:builder-onbuild',
                size: 1,
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
                jobs: [
                  {
                    id: 1149822131854,
                    name: 'image:builder-onbuild',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                    play_path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                    playable: true,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.728Z',
                    updated_at: '2018-10-31T16:35:24.070Z',
                    status: {
                      icon: 'status_manual',
                      text: 'manual',
                      label: 'manual play action',
                      group: 'manual',
                      tooltip: 'manual action',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                  },
                ],
              },
              {
                name: 'image:nginx-onbuild',
                size: 1,
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
                jobs: [
                  {
                    id: 11498285523424,
                    name: 'image:nginx-onbuild',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                    play_path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                    playable: true,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.753Z',
                    updated_at: '2018-10-31T16:35:24.033Z',
                    status: {
                      icon: 'status_manual',
                      text: 'manual',
                      label: 'manual play action',
                      group: 'manual',
                      tooltip: 'manual action',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                  },
                ],
              },
            ],
            status: {
              icon: 'status_skipped',
              text: 'skipped',
              label: 'skipped',
              group: 'skipped',
              tooltip: 'skipped',
              has_details: true,
              details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#build-images',
              illustration: null,
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
            },
            path: '/gitlab-com/gitlab-docs/pipelines/34993051#build-images',
            dropdown_path:
              '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=build-images',
          },
          {
            name: 'build',
            title: 'build: failed',
            groups: [
              {
                name: 'compile_dev',
                size: 1,
                status: {
                  icon: 'status_failed',
                  text: 'failed',
                  label: 'failed',
                  group: 'failed',
                  tooltip: 'failed - (script failure)',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job does not have a trace.',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                  action: {
                    icon: 'retry',
                    title: 'Retry',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114984694/retry',
                    method: 'post',
                    button_title: 'Retry this job',
                  },
                },
                jobs: [
                  {
                    id: 1149846949786,
                    name: 'compile_dev',
                    started: '2018-10-31T16:39:41.598Z',
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                    retry_path: '/gitlab-com/gitlab-docs/-/jobs/114984694/retry',
                    playable: false,
                    scheduled: false,
                    created_at: '2018-10-31T16:39:41.138Z',
                    updated_at: '2018-10-31T16:41:40.072Z',
                    status: {
                      icon: 'status_failed',
                      text: 'failed',
                      label: 'failed',
                      group: 'failed',
                      tooltip: 'failed - (script failure)',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114984694/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    recoverable: false,
                  },
                ],
              },
            ],
            status: {
              icon: 'status_failed',
              text: 'failed',
              label: 'failed',
              group: 'failed',
              tooltip: 'failed',
              has_details: true,
              details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#build',
              illustration: null,
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
            },
            path: '/gitlab-com/gitlab-docs/pipelines/34993051#build',
            dropdown_path: '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=build',
          },
          {
            name: 'deploy',
            title: 'deploy: skipped',
            groups: [
              {
                name: 'review',
                size: 1,
                status: {
                  icon: 'status_skipped',
                  text: 'skipped',
                  label: 'skipped',
                  group: 'skipped',
                  tooltip: 'skipped',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job has been skipped',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                },
                jobs: [
                  {
                    id: 11498282342357,
                    name: 'review',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                    playable: false,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.805Z',
                    updated_at: '2018-10-31T16:41:40.569Z',
                    status: {
                      icon: 'status_skipped',
                      text: 'skipped',
                      label: 'skipped',
                      group: 'skipped',
                      tooltip: 'skipped',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job has been skipped',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                    },
                  },
                ],
              },
              {
                name: 'review_stop',
                size: 1,
                status: {
                  icon: 'status_skipped',
                  text: 'skipped',
                  label: 'skipped',
                  group: 'skipped',
                  tooltip: 'skipped',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job has been skipped',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                },
                jobs: [
                  {
                    id: 114982858,
                    name: 'review_stop',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                    playable: false,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.840Z',
                    updated_at: '2018-10-31T16:41:40.480Z',
                    status: {
                      icon: 'status_skipped',
                      text: 'skipped',
                      label: 'skipped',
                      group: 'skipped',
                      tooltip: 'skipped',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job has been skipped',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                    },
                  },
                ],
              },
            ],
            status: {
              icon: 'status_skipped',
              text: 'skipped',
              label: 'skipped',
              group: 'skipped',
              tooltip: 'skipped',
              has_details: true,
              details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#deploy',
              illustration: null,
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
            },
            path: '/gitlab-com/gitlab-docs/pipelines/34993051#deploy',
            dropdown_path: '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=deploy',
          },
        ],
        artifacts: [],
        manual_actions: [
          {
            name: 'image:bootstrap',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
            playable: true,
            scheduled: false,
          },
          {
            name: 'image:builder-onbuild',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
            playable: true,
            scheduled: false,
          },
          {
            name: 'image:nginx-onbuild',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
            playable: true,
            scheduled: false,
          },
          {
            name: 'review_stop',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982858/play',
            playable: false,
            scheduled: false,
          },
        ],
        scheduled_actions: [],
      },
      project: {
        id: 20,
        name: 'GitLab Docs',
        full_path: '/gitlab-com/gitlab-docs',
        full_name: 'GitLab.com / GitLab Docs',
      },
    },
    triggered: [],
  },
  triggered: [
    {
      id: 34993051,
      user: {
        id: 376774,
        name: 'Alessio Caiazza',
        username: 'nolith',
        state: 'active',
        avatar_url:
          'https://assets.gitlab-static.net/uploads/-/system/user/avatar/376774/avatar.png',
        web_url: 'https://gitlab.com/nolith',
        status_tooltip_html: null,
        path: '/nolith',
      },
      active: false,
      coverage: null,
      source: 'pipeline',
      source_job: {
        name: 'trigger_job',
      },
      path: '/gitlab-com/gitlab-docs/pipelines/34993051',
      details: {
        status: {
          icon: 'status_failed',
          text: 'failed',
          label: 'failed',
          group: 'failed',
          tooltip: 'failed',
          has_details: true,
          details_path: '/gitlab-com/gitlab-docs/pipelines/34993051',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
        },
        duration: 118,
        finished_at: '2018-10-31T16:41:40.615Z',
        stages: [
          {
            name: 'build-images',
            title: 'build-images: skipped',
            groups: [
              {
                name: 'image:bootstrap',
                size: 1,
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
                jobs: [
                  {
                    id: 114982853,
                    name: 'image:bootstrap',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                    play_path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                    playable: true,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.704Z',
                    updated_at: '2018-10-31T16:35:24.118Z',
                    status: {
                      icon: 'status_manual',
                      text: 'manual',
                      label: 'manual play action',
                      group: 'manual',
                      tooltip: 'manual action',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                  },
                ],
              },
              {
                name: 'image:builder-onbuild',
                size: 1,
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
                jobs: [
                  {
                    id: 114982854,
                    name: 'image:builder-onbuild',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                    play_path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                    playable: true,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.728Z',
                    updated_at: '2018-10-31T16:35:24.070Z',
                    status: {
                      icon: 'status_manual',
                      text: 'manual',
                      label: 'manual play action',
                      group: 'manual',
                      tooltip: 'manual action',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                  },
                ],
              },
              {
                name: 'image:nginx-onbuild',
                size: 1,
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
                jobs: [
                  {
                    id: 114982855,
                    name: 'image:nginx-onbuild',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                    play_path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                    playable: true,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.753Z',
                    updated_at: '2018-10-31T16:35:24.033Z',
                    status: {
                      icon: 'status_manual',
                      text: 'manual',
                      label: 'manual play action',
                      group: 'manual',
                      tooltip: 'manual action',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                  },
                ],
              },
            ],
            status: {
              icon: 'status_skipped',
              text: 'skipped',
              label: 'skipped',
              group: 'skipped',
              tooltip: 'skipped',
              has_details: true,
              details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#build-images',
              illustration: null,
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
            },
            path: '/gitlab-com/gitlab-docs/pipelines/34993051#build-images',
            dropdown_path:
              '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=build-images',
          },
          {
            name: 'build',
            title: 'build: failed',
            groups: [
              {
                name: 'compile_dev',
                size: 1,
                status: {
                  icon: 'status_failed',
                  text: 'failed',
                  label: 'failed',
                  group: 'failed',
                  tooltip: 'failed - (script failure)',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job does not have a trace.',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                  action: {
                    icon: 'retry',
                    title: 'Retry',
                    path: '/h5bp/html5-boilerplate/-/jobs/528/retry',
                    method: 'post',
                    button_title: 'Retry this job',
                  },
                },
                jobs: [
                  {
                    id: 114984694,
                    name: 'compile_dev',
                    started: '2018-10-31T16:39:41.598Z',
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                    retry_path: '/gitlab-com/gitlab-docs/-/jobs/114984694/retry',
                    playable: false,
                    scheduled: false,
                    created_at: '2018-10-31T16:39:41.138Z',
                    updated_at: '2018-10-31T16:41:40.072Z',
                    status: {
                      icon: 'status_failed',
                      text: 'failed',
                      label: 'failed',
                      group: 'failed',
                      tooltip: 'failed - (script failure)',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/528/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    recoverable: false,
                  },
                ],
              },
            ],
            status: {
              icon: 'status_failed',
              text: 'failed',
              label: 'failed',
              group: 'failed',
              tooltip: 'failed',
              has_details: true,
              details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#build',
              illustration: null,
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
            },
            path: '/gitlab-com/gitlab-docs/pipelines/34993051#build',
            dropdown_path: '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=build',
          },
          {
            name: 'deploy',
            title: 'deploy: skipped',
            groups: [
              {
                name: 'review',
                size: 1,
                status: {
                  icon: 'status_skipped',
                  text: 'skipped',
                  label: 'skipped',
                  group: 'skipped',
                  tooltip: 'skipped',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job has been skipped',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                },
                jobs: [
                  {
                    id: 114982857,
                    name: 'review',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                    playable: false,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.805Z',
                    updated_at: '2018-10-31T16:41:40.569Z',
                    status: {
                      icon: 'status_skipped',
                      text: 'skipped',
                      label: 'skipped',
                      group: 'skipped',
                      tooltip: 'skipped',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job has been skipped',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                    },
                  },
                ],
              },
              {
                name: 'review_stop',
                size: 1,
                status: {
                  icon: 'status_skipped',
                  text: 'skipped',
                  label: 'skipped',
                  group: 'skipped',
                  tooltip: 'skipped',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job has been skipped',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                },
                jobs: [
                  {
                    id: 114982858,
                    name: 'review_stop',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                    playable: false,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.840Z',
                    updated_at: '2018-10-31T16:41:40.480Z',
                    status: {
                      icon: 'status_skipped',
                      text: 'skipped',
                      label: 'skipped',
                      group: 'skipped',
                      tooltip: 'skipped',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job has been skipped',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                    },
                  },
                ],
              },
            ],
            status: {
              icon: 'status_skipped',
              text: 'skipped',
              label: 'skipped',
              group: 'skipped',
              tooltip: 'skipped',
              has_details: true,
              details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#deploy',
              illustration: null,
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
            },
            path: '/gitlab-com/gitlab-docs/pipelines/34993051#deploy',
            dropdown_path: '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=deploy',
          },
        ],
        artifacts: [],
        manual_actions: [
          {
            name: 'image:bootstrap',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
            playable: true,
            scheduled: false,
          },
          {
            name: 'image:builder-onbuild',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
            playable: true,
            scheduled: false,
          },
          {
            name: 'image:nginx-onbuild',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
            playable: true,
            scheduled: false,
          },
          {
            name: 'review_stop',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982858/play',
            playable: false,
            scheduled: false,
          },
        ],
        scheduled_actions: [],
      },
      project: {
        id: 20,
        name: 'GitLab Docs',
        full_path: '/gitlab-com/gitlab-docs',
        full_name: 'GitLab.com / GitLab Docs',
      },
    },
    {
      id: 34993052,
      user: {
        id: 376774,
        name: 'Alessio Caiazza',
        username: 'nolith',
        state: 'active',
        avatar_url:
          'https://assets.gitlab-static.net/uploads/-/system/user/avatar/376774/avatar.png',
        web_url: 'https://gitlab.com/nolith',
        status_tooltip_html: null,
        path: '/nolith',
      },
      active: false,
      coverage: null,
      source: 'pipeline',
      source_job: {
        name: 'trigger_job',
      },
      path: '/gitlab-com/gitlab-docs/pipelines/34993051',
      details: {
        status: {
          icon: 'status_failed',
          text: 'failed',
          label: 'failed',
          group: 'failed',
          tooltip: 'failed',
          has_details: true,
          details_path: '/gitlab-com/gitlab-docs/pipelines/34993051',
          illustration: null,
          favicon:
            'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
        },
        duration: 118,
        finished_at: '2018-10-31T16:41:40.615Z',
        stages: [
          {
            name: 'build-images',
            title: 'build-images: skipped',
            groups: [
              {
                name: 'image:bootstrap',
                size: 1,
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
                jobs: [
                  {
                    id: 114982853,
                    name: 'image:bootstrap',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                    play_path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                    playable: true,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.704Z',
                    updated_at: '2018-10-31T16:35:24.118Z',
                    status: {
                      icon: 'status_manual',
                      text: 'manual',
                      label: 'manual play action',
                      group: 'manual',
                      tooltip: 'manual action',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982853',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                  },
                ],
              },
              {
                name: 'image:builder-onbuild',
                size: 1,
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
                jobs: [
                  {
                    id: 114982854,
                    name: 'image:builder-onbuild',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                    play_path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                    playable: true,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.728Z',
                    updated_at: '2018-10-31T16:35:24.070Z',
                    status: {
                      icon: 'status_manual',
                      text: 'manual',
                      label: 'manual play action',
                      group: 'manual',
                      tooltip: 'manual action',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982854',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                  },
                ],
              },
              {
                name: 'image:nginx-onbuild',
                size: 1,
                status: {
                  icon: 'status_manual',
                  text: 'manual',
                  label: 'manual play action',
                  group: 'manual',
                  tooltip: 'manual action',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                    size: 'svg-394',
                    title: 'This job requires a manual action',
                    content:
                      'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                  action: {
                    icon: 'play',
                    title: 'Play',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                    method: 'post',
                    button_title: 'Trigger this manual action',
                  },
                },
                jobs: [
                  {
                    id: 1224982855,
                    name: 'image:nginx-onbuild',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                    play_path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                    playable: true,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.753Z',
                    updated_at: '2018-10-31T16:35:24.033Z',
                    status: {
                      icon: 'status_manual',
                      text: 'manual',
                      label: 'manual play action',
                      group: 'manual',
                      tooltip: 'manual action',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982855',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                  },
                ],
              },
            ],
            status: {
              icon: 'status_skipped',
              text: 'skipped',
              label: 'skipped',
              group: 'skipped',
              tooltip: 'skipped',
              has_details: true,
              details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#build-images',
              illustration: null,
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
            },
            path: '/gitlab-com/gitlab-docs/pipelines/34993051#build-images',
            dropdown_path:
              '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=build-images',
          },
          {
            name: 'build',
            title: 'build: failed',
            groups: [
              {
                name: 'compile_dev',
                size: 1,
                status: {
                  icon: 'status_failed',
                  text: 'failed',
                  label: 'failed',
                  group: 'failed',
                  tooltip: 'failed - (script failure)',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job does not have a trace.',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                  action: {
                    icon: 'retry',
                    title: 'Retry',
                    path: '/gitlab-com/gitlab-docs/-/jobs/114984694/retry',
                    method: 'post',
                    button_title: 'Retry this job',
                  },
                },
                jobs: [
                  {
                    id: 1123984694,
                    name: 'compile_dev',
                    started: '2018-10-31T16:39:41.598Z',
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                    retry_path: '/gitlab-com/gitlab-docs/-/jobs/114984694/retry',
                    playable: false,
                    scheduled: false,
                    created_at: '2018-10-31T16:39:41.138Z',
                    updated_at: '2018-10-31T16:41:40.072Z',
                    status: {
                      icon: 'status_failed',
                      text: 'failed',
                      label: 'failed',
                      group: 'failed',
                      tooltip: 'failed - (script failure)',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114984694',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/gitlab-com/gitlab-docs/-/jobs/114984694/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    recoverable: false,
                  },
                ],
              },
            ],
            status: {
              icon: 'status_failed',
              text: 'failed',
              label: 'failed',
              group: 'failed',
              tooltip: 'failed',
              has_details: true,
              details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#build',
              illustration: null,
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
            },
            path: '/gitlab-com/gitlab-docs/pipelines/34993051#build',
            dropdown_path: '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=build',
          },
          {
            name: 'deploy',
            title: 'deploy: skipped',
            groups: [
              {
                name: 'review',
                size: 1,
                status: {
                  icon: 'status_skipped',
                  text: 'skipped',
                  label: 'skipped',
                  group: 'skipped',
                  tooltip: 'skipped',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job has been skipped',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                },
                jobs: [
                  {
                    id: 1143232982857,
                    name: 'review',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                    playable: false,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.805Z',
                    updated_at: '2018-10-31T16:41:40.569Z',
                    status: {
                      icon: 'status_skipped',
                      text: 'skipped',
                      label: 'skipped',
                      group: 'skipped',
                      tooltip: 'skipped',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982857',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job has been skipped',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                    },
                  },
                ],
              },
              {
                name: 'review_stop',
                size: 1,
                status: {
                  icon: 'status_skipped',
                  text: 'skipped',
                  label: 'skipped',
                  group: 'skipped',
                  tooltip: 'skipped',
                  has_details: true,
                  details_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                  illustration: {
                    image:
                      'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                    size: 'svg-430',
                    title: 'This job has been skipped',
                  },
                  favicon:
                    'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                },
                jobs: [
                  {
                    id: 114921313182858,
                    name: 'review_stop',
                    started: null,
                    archived: false,
                    build_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                    playable: false,
                    scheduled: false,
                    created_at: '2018-10-31T16:35:23.840Z',
                    updated_at: '2018-10-31T16:41:40.480Z',
                    status: {
                      icon: 'status_skipped',
                      text: 'skipped',
                      label: 'skipped',
                      group: 'skipped',
                      tooltip: 'skipped',
                      has_details: true,
                      details_path: '/gitlab-com/gitlab-docs/-/jobs/114982858',
                      illustration: {
                        image:
                          'https://assets.gitlab-static.net/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job has been skipped',
                      },
                      favicon:
                        'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                    },
                  },
                ],
              },
            ],
            status: {
              icon: 'status_skipped',
              text: 'skipped',
              label: 'skipped',
              group: 'skipped',
              tooltip: 'skipped',
              has_details: true,
              details_path: '/gitlab-com/gitlab-docs/pipelines/34993051#deploy',
              illustration: null,
              favicon:
                'https://gitlab.com/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
            },
            path: '/gitlab-com/gitlab-docs/pipelines/34993051#deploy',
            dropdown_path: '/gitlab-com/gitlab-docs/pipelines/34993051/stage.json?stage=deploy',
          },
        ],
        artifacts: [],
        manual_actions: [
          {
            name: 'image:bootstrap',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982853/play',
            playable: true,
            scheduled: false,
          },
          {
            name: 'image:builder-onbuild',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982854/play',
            playable: true,
            scheduled: false,
          },
          {
            name: 'image:nginx-onbuild',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982855/play',
            playable: true,
            scheduled: false,
          },
          {
            name: 'review_stop',
            path: '/gitlab-com/gitlab-docs/-/jobs/114982858/play',
            playable: false,
            scheduled: false,
          },
        ],
        scheduled_actions: [],
      },
      project: {
        id: 20,
        name: 'GitLab Docs',
        full_path: '/gitlab-com/gitlab-docs',
        full_name: 'GitLab.com / GitLab Docs',
      },
      triggered: [
        {
          id: 26,
          user: null,
          active: false,
          coverage: null,
          source: 'push',
          source_job: {
            name: 'trigger_job',
          },
          created_at: '2019-01-06T17:48:37.599Z',
          updated_at: '2019-01-06T17:48:38.371Z',
          path: '/h5bp/html5-boilerplate/pipelines/26',
          flags: {
            latest: true,
            stuck: false,
            auto_devops: false,
            merge_request: false,
            yaml_errors: false,
            retryable: true,
            cancelable: false,
            failure_reason: false,
          },
          details: {
            status: {
              icon: 'status_warning',
              text: 'passed',
              label: 'passed with warnings',
              group: 'success-with-warnings',
              tooltip: 'passed',
              has_details: true,
              details_path: '/h5bp/html5-boilerplate/pipelines/26',
              illustration: null,
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
            },
            duration: null,
            finished_at: '2019-01-06T17:48:38.370Z',
            stages: [
              {
                name: 'build',
                title: 'build: passed',
                groups: [
                  {
                    name: 'build:linux',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/526',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/526/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 526,
                        name: 'build:linux',
                        started: '2019-01-06T08:48:20.236Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/526',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/526/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:37.806Z',
                        updated_at: '2019-01-06T17:48:37.806Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/526',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/526/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                  {
                    name: 'build:osx',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/527',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/527/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 527,
                        name: 'build:osx',
                        started: '2019-01-06T07:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/527',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/527/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:37.846Z',
                        updated_at: '2019-01-06T17:48:37.846Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/527',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/527/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                ],
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'passed',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/h5bp/html5-boilerplate/pipelines/26#build',
                  illustration: null,
                  favicon:
                    '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                },
                path: '/h5bp/html5-boilerplate/pipelines/26#build',
                dropdown_path: '/h5bp/html5-boilerplate/pipelines/26/stage.json?stage=build',
              },
              {
                name: 'test',
                title: 'test: passed with warnings',
                groups: [
                  {
                    name: 'jenkins',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: null,
                      group: 'success',
                      tooltip: null,
                      has_details: false,
                      details_path: null,
                      illustration: null,
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                    },
                    jobs: [
                      {
                        id: 546,
                        name: 'jenkins',
                        started: '2019-01-06T11:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/546',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.359Z',
                        updated_at: '2019-01-06T17:48:38.359Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: null,
                          group: 'success',
                          tooltip: null,
                          has_details: false,
                          details_path: null,
                          illustration: null,
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                        },
                      },
                    ],
                  },
                  {
                    name: 'rspec:linux',
                    size: 3,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: false,
                      details_path: null,
                      illustration: null,
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                    },
                    jobs: [
                      {
                        id: 528,
                        name: 'rspec:linux 0 3',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/528',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/528/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:37.885Z',
                        updated_at: '2019-01-06T17:48:37.885Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/528',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/528/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                      {
                        id: 529,
                        name: 'rspec:linux 1 3',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/529',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/529/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:37.907Z',
                        updated_at: '2019-01-06T17:48:37.907Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/529',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/529/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                      {
                        id: 530,
                        name: 'rspec:linux 2 3',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/530',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/530/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:37.927Z',
                        updated_at: '2019-01-06T17:48:37.927Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/530',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/530/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                  {
                    name: 'rspec:osx',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/535',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/535/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 535,
                        name: 'rspec:osx',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/535',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/535/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.018Z',
                        updated_at: '2019-01-06T17:48:38.018Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/535',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/535/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                  {
                    name: 'rspec:windows',
                    size: 3,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: false,
                      details_path: null,
                      illustration: null,
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                    },
                    jobs: [
                      {
                        id: 531,
                        name: 'rspec:windows 0 3',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/531',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/531/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:37.944Z',
                        updated_at: '2019-01-06T17:48:37.944Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/531',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/531/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                      {
                        id: 532,
                        name: 'rspec:windows 1 3',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/532',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/532/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:37.962Z',
                        updated_at: '2019-01-06T17:48:37.962Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/532',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/532/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                      {
                        id: 534,
                        name: 'rspec:windows 2 3',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/534',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/534/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:37.999Z',
                        updated_at: '2019-01-06T17:48:37.999Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/534',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/534/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                  {
                    name: 'spinach:linux',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/536',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/536/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 536,
                        name: 'spinach:linux',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/536',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/536/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.050Z',
                        updated_at: '2019-01-06T17:48:38.050Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/536',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/536/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                  {
                    name: 'spinach:osx',
                    size: 1,
                    status: {
                      icon: 'status_warning',
                      text: 'failed',
                      label: 'failed (allowed to fail)',
                      group: 'failed-with-warnings',
                      tooltip: 'failed - (unknown failure) (allowed to fail)',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/537',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/537/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 537,
                        name: 'spinach:osx',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/537',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/537/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.069Z',
                        updated_at: '2019-01-06T17:48:38.069Z',
                        status: {
                          icon: 'status_warning',
                          text: 'failed',
                          label: 'failed (allowed to fail)',
                          group: 'failed-with-warnings',
                          tooltip: 'failed - (unknown failure) (allowed to fail)',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/537',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/537/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                        callout_message: 'There is an unknown failure, please try again',
                        recoverable: true,
                      },
                    ],
                  },
                ],
                status: {
                  icon: 'status_warning',
                  text: 'passed',
                  label: 'passed with warnings',
                  group: 'success-with-warnings',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/h5bp/html5-boilerplate/pipelines/26#test',
                  illustration: null,
                  favicon:
                    '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                },
                path: '/h5bp/html5-boilerplate/pipelines/26#test',
                dropdown_path: '/h5bp/html5-boilerplate/pipelines/26/stage.json?stage=test',
              },
              {
                name: 'security',
                title: 'security: passed',
                groups: [
                  {
                    name: 'container_scanning',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/541',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/541/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 541,
                        name: 'container_scanning',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/541',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/541/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.186Z',
                        updated_at: '2019-01-06T17:48:38.186Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/541',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/541/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                  {
                    name: 'dast',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/538',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/538/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 538,
                        name: 'dast',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/538',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/538/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.087Z',
                        updated_at: '2019-01-06T17:48:38.087Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/538',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/538/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                  {
                    name: 'dependency_scanning',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/540',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/540/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 540,
                        name: 'dependency_scanning',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/540',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/540/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.153Z',
                        updated_at: '2019-01-06T17:48:38.153Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/540',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/540/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                  {
                    name: 'sast',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/539',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/539/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 539,
                        name: 'sast',
                        started: '2019-01-06T09:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/539',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/539/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.121Z',
                        updated_at: '2019-01-06T17:48:38.121Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/539',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/539/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                ],
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'passed',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/h5bp/html5-boilerplate/pipelines/26#security',
                  illustration: null,
                  favicon:
                    '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                },
                path: '/h5bp/html5-boilerplate/pipelines/26#security',
                dropdown_path: '/h5bp/html5-boilerplate/pipelines/26/stage.json?stage=security',
              },
              {
                name: 'deploy',
                title: 'deploy: passed',
                groups: [
                  {
                    name: 'production',
                    size: 1,
                    status: {
                      icon: 'status_skipped',
                      text: 'skipped',
                      label: 'skipped',
                      group: 'skipped',
                      tooltip: 'skipped',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/544',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job has been skipped',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                    },
                    jobs: [
                      {
                        id: 544,
                        name: 'production',
                        started: null,
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/544',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.313Z',
                        updated_at: '2019-01-06T17:48:38.313Z',
                        status: {
                          icon: 'status_skipped',
                          text: 'skipped',
                          label: 'skipped',
                          group: 'skipped',
                          tooltip: 'skipped',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/544',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job has been skipped',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                        },
                      },
                    ],
                  },
                  {
                    name: 'staging',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'passed',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/542',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job does not have a trace.',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'retry',
                        title: 'Retry',
                        path: '/h5bp/html5-boilerplate/-/jobs/542/retry',
                        method: 'post',
                        button_title: 'Retry this job',
                      },
                    },
                    jobs: [
                      {
                        id: 542,
                        name: 'staging',
                        started: '2019-01-06T11:48:20.237Z',
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/542',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/542/retry',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.219Z',
                        updated_at: '2019-01-06T17:48:38.219Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'passed',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/542',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job does not have a trace.',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'retry',
                            title: 'Retry',
                            path: '/h5bp/html5-boilerplate/-/jobs/542/retry',
                            method: 'post',
                            button_title: 'Retry this job',
                          },
                        },
                      },
                    ],
                  },
                  {
                    name: 'stop staging',
                    size: 1,
                    status: {
                      icon: 'status_skipped',
                      text: 'skipped',
                      label: 'skipped',
                      group: 'skipped',
                      tooltip: 'skipped',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/543',
                      illustration: {
                        image:
                          '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                        size: 'svg-430',
                        title: 'This job has been skipped',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                    },
                    jobs: [
                      {
                        id: 543,
                        name: 'stop staging',
                        started: null,
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/543',
                        playable: false,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.283Z',
                        updated_at: '2019-01-06T17:48:38.283Z',
                        status: {
                          icon: 'status_skipped',
                          text: 'skipped',
                          label: 'skipped',
                          group: 'skipped',
                          tooltip: 'skipped',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/543',
                          illustration: {
                            image:
                              '/assets/illustrations/skipped-job_empty-8b877955fbf175e42ae65b6cb95346e15282c6fc5b682756c329af3a0055225e.svg',
                            size: 'svg-430',
                            title: 'This job has been skipped',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_skipped-0b9c5e543588945e8c4ca57786bbf2d0c56631959c9f853300392d0315be829b.png',
                        },
                      },
                    ],
                  },
                ],
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'passed',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/h5bp/html5-boilerplate/pipelines/26#deploy',
                  illustration: null,
                  favicon:
                    '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                },
                path: '/h5bp/html5-boilerplate/pipelines/26#deploy',
                dropdown_path: '/h5bp/html5-boilerplate/pipelines/26/stage.json?stage=deploy',
              },
              {
                name: 'notify',
                title: 'notify: passed',
                groups: [
                  {
                    name: 'slack',
                    size: 1,
                    status: {
                      icon: 'status_success',
                      text: 'passed',
                      label: 'manual play action',
                      group: 'success',
                      tooltip: 'passed',
                      has_details: true,
                      details_path: '/h5bp/html5-boilerplate/-/jobs/545',
                      illustration: {
                        image:
                          '/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                        size: 'svg-394',
                        title: 'This job requires a manual action',
                        content:
                          'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                      },
                      favicon:
                        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                      action: {
                        icon: 'play',
                        title: 'Play',
                        path: '/h5bp/html5-boilerplate/-/jobs/545/play',
                        method: 'post',
                        button_title: 'Trigger this manual action',
                      },
                    },
                    jobs: [
                      {
                        id: 545,
                        name: 'slack',
                        started: null,
                        archived: false,
                        build_path: '/h5bp/html5-boilerplate/-/jobs/545',
                        retry_path: '/h5bp/html5-boilerplate/-/jobs/545/retry',
                        play_path: '/h5bp/html5-boilerplate/-/jobs/545/play',
                        playable: true,
                        scheduled: false,
                        created_at: '2019-01-06T17:48:38.341Z',
                        updated_at: '2019-01-06T17:48:38.341Z',
                        status: {
                          icon: 'status_success',
                          text: 'passed',
                          label: 'manual play action',
                          group: 'success',
                          tooltip: 'passed',
                          has_details: true,
                          details_path: '/h5bp/html5-boilerplate/-/jobs/545',
                          illustration: {
                            image:
                              '/assets/illustrations/manual_action-2b4ca0d1bcfd92aebf33d484e36cbf7a102d007f76b5a0cfea636033a629d601.svg',
                            size: 'svg-394',
                            title: 'This job requires a manual action',
                            content:
                              'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
                          },
                          favicon:
                            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                          action: {
                            icon: 'play',
                            title: 'Play',
                            path: '/h5bp/html5-boilerplate/-/jobs/545/play',
                            method: 'post',
                            button_title: 'Trigger this manual action',
                          },
                        },
                      },
                    ],
                  },
                ],
                status: {
                  icon: 'status_success',
                  text: 'passed',
                  label: 'passed',
                  group: 'success',
                  tooltip: 'passed',
                  has_details: true,
                  details_path: '/h5bp/html5-boilerplate/pipelines/26#notify',
                  illustration: null,
                  favicon:
                    '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
                },
                path: '/h5bp/html5-boilerplate/pipelines/26#notify',
                dropdown_path: '/h5bp/html5-boilerplate/pipelines/26/stage.json?stage=notify',
              },
            ],
            artifacts: [
              {
                name: 'build:linux',
                expired: null,
                expire_at: null,
                path: '/h5bp/html5-boilerplate/-/jobs/526/artifacts/download',
                browse_path: '/h5bp/html5-boilerplate/-/jobs/526/artifacts/browse',
              },
              {
                name: 'build:osx',
                expired: null,
                expire_at: null,
                path: '/h5bp/html5-boilerplate/-/jobs/527/artifacts/download',
                browse_path: '/h5bp/html5-boilerplate/-/jobs/527/artifacts/browse',
              },
            ],
            manual_actions: [
              {
                name: 'stop staging',
                path: '/h5bp/html5-boilerplate/-/jobs/543/play',
                playable: false,
                scheduled: false,
              },
              {
                name: 'production',
                path: '/h5bp/html5-boilerplate/-/jobs/544/play',
                playable: false,
                scheduled: false,
              },
              {
                name: 'slack',
                path: '/h5bp/html5-boilerplate/-/jobs/545/play',
                playable: true,
                scheduled: false,
              },
            ],
            scheduled_actions: [],
          },
          ref: {
            name: 'main',
            path: '/h5bp/html5-boilerplate/commits/main',
            tag: false,
            branch: true,
            merge_request: false,
          },
          commit: {
            id: 'bad98c453eab56d20057f3929989251d45cd1a8b',
            short_id: 'bad98c45',
            title: 'remove instances of shrink-to-fit=no (#2103)',
            created_at: '2018-12-17T20:52:18.000Z',
            parent_ids: ['49130f6cfe9ff1f749015d735649a2bc6f66cf3a'],
            message:
              'remove instances of shrink-to-fit=no (#2103)\n\ncloses #2102\r\n\r\nPer my findings, the need for it as a default was rectified with the release of iOS 9.3, where the viewport no longer shrunk to accommodate overflow, as was introduced in iOS 9.',
            author_name: "Scott O'Hara",
            author_email: 'scottaohara@users.noreply.github.com',
            authored_date: '2018-12-17T20:52:18.000Z',
            committer_name: 'Rob Larsen',
            committer_email: 'rob@drunkenfist.com',
            committed_date: '2018-12-17T20:52:18.000Z',
            author: null,
            author_gravatar_url:
              'https://www.gravatar.com/avatar/6d597df7cf998d16cbe00ccac063b31e?s=80\u0026d=identicon',
            commit_url:
              'http://localhost:3001/h5bp/html5-boilerplate/commit/bad98c453eab56d20057f3929989251d45cd1a8b',
            commit_path: '/h5bp/html5-boilerplate/commit/bad98c453eab56d20057f3929989251d45cd1a8b',
          },
          retry_path: '/h5bp/html5-boilerplate/pipelines/26/retry',
          triggered_by: {
            id: 4,
            user: null,
            active: false,
            coverage: null,
            source: 'push',
            source_job: {
              name: 'trigger_job',
            },
            path: '/gitlab-org/gitlab-test/pipelines/4',
            details: {
              status: {
                icon: 'status_warning',
                text: 'passed',
                label: 'passed with warnings',
                group: 'success-with-warnings',
                tooltip: 'passed',
                has_details: true,
                details_path: '/gitlab-org/gitlab-test/pipelines/4',
                illustration: null,
                favicon:
                  '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              },
            },
            project: {
              id: 1,
              name: 'Gitlab Test',
              full_path: '/gitlab-org/gitlab-test',
              full_name: 'Gitlab Org / Gitlab Test',
            },
          },
          triggered: [],
          project: {
            id: 20,
            name: 'GitLab Docs',
            full_path: '/gitlab-com/gitlab-docs',
            full_name: 'GitLab.com / GitLab Docs',
          },
        },
      ],
    },
  ],
};
