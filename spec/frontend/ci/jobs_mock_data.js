import mockJobsCount from 'test_fixtures/graphql/jobs/get_jobs_count.query.graphql.json';
import mockAllJobsCount from 'test_fixtures/graphql/jobs/get_all_jobs_count.query.graphql.json';
import mockJobsEmpty from 'test_fixtures/graphql/jobs/get_jobs.query.graphql.empty.json';
import mockAllJobsEmpty from 'test_fixtures/graphql/jobs/get_all_jobs.query.graphql.empty.json';
import mockJobsPaginated from 'test_fixtures/graphql/jobs/get_jobs.query.graphql.paginated.json';
import mockAllJobsPaginated from 'test_fixtures/graphql/jobs/get_all_jobs.query.graphql.paginated.json';
import mockJobs from 'test_fixtures/graphql/jobs/get_jobs.query.graphql.json';
import mockAllJobs from 'test_fixtures/graphql/jobs/get_all_jobs.query.graphql.json';
import mockJobsAsGuest from 'test_fixtures/graphql/jobs/get_jobs.query.graphql.as_guest.json';
import mockCancelableJobsCount from 'test_fixtures/graphql/jobs/get_cancelable_jobs_count.query.graphql.json';
import { TEST_HOST } from 'spec/test_constants';
import { TOKEN_TYPE_STATUS } from '~/vue_shared/components/filtered_search_bar/constants';

const threeWeeksAgo = new Date();
threeWeeksAgo.setDate(threeWeeksAgo.getDate() - 21);

// Fixtures generated at spec/frontend/fixtures/jobs.rb
export const mockJobsResponsePaginated = mockJobsPaginated;
export const mockAllJobsResponsePaginated = mockAllJobsPaginated;
export const mockJobsResponseEmpty = mockJobsEmpty;
export const mockAllJobsResponseEmpty = mockAllJobsEmpty;
export const mockJobsNodes = mockJobs.data.project.jobs.nodes;
export const mockAllJobsNodes = mockAllJobs.data.jobs.nodes;
export const mockJobsNodesAsGuest = mockJobsAsGuest.data.project.jobs.nodes;
export const mockJobsCountResponse = mockJobsCount;
export const mockAllJobsCountResponse = mockAllJobsCount;
export const mockCancelableJobsCountResponse = mockCancelableJobsCount;

export const stages = [
  {
    name: 'build',
    title: 'build: running',
    groups: [
      {
        name: 'build:linux',
        size: 1,
        status: {
          icon: 'status_pending',
          text: 'pending',
          label: 'pending',
          group: 'pending',
          tooltip: 'pending',
          has_details: true,
          details_path: '/gitlab-org/gitlab-shell/-/jobs/1180',
          illustration: {
            image: 'illustrations/empty-state/empty-job-pending-md.svg',
            size: 'svg-content svg-430',
            title: 'This job has not started yet',
            content: 'This job is in pending state and is waiting to be picked by a runner',
          },
          favicon:
            '/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png',
          action: {
            icon: 'cancel',
            title: 'Cancel',
            path: '/gitlab-org/gitlab-shell/-/jobs/1180/cancel',
            method: 'post',
          },
        },
        jobs: [
          {
            id: 1180,
            name: 'build:linux',
            started: false,
            build_path: '/gitlab-org/gitlab-shell/-/jobs/1180',
            cancel_path: '/gitlab-org/gitlab-shell/-/jobs/1180/cancel',
            playable: false,
            created_at: '2018-09-28T11:09:57.229Z',
            updated_at: '2018-09-28T11:09:57.503Z',
            status: {
              icon: 'status_pending',
              text: 'pending',
              label: 'pending',
              group: 'pending',
              tooltip: 'pending',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/1180',
              illustration: {
                image: 'illustrations/empty-state/empty-job-pending-md.svg',
                size: 'svg-content svg-430',
                title: 'This job has not started yet',
                content: 'This job is in pending state and is waiting to be picked by a runner',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png',
              action: {
                icon: 'cancel',
                title: 'Cancel',
                path: '/gitlab-org/gitlab-shell/-/jobs/1180/cancel',
                method: 'post',
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
          details_path: '/gitlab-org/gitlab-shell/-/jobs/444',
          illustration: {
            image: 'illustrations/empty-state/empty-job-skipped-md.svg',
            size: 'svg-content svg-430',
            title: 'This job does not have a trace.',
          },
          favicon:
            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
          action: {
            icon: 'retry',
            title: 'Retry',
            path: '/gitlab-org/gitlab-shell/-/jobs/444/retry',
            method: 'post',
          },
        },
        jobs: [
          {
            id: 444,
            name: 'build:osx',
            started: '2018-05-18T05:32:20.655Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/444',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/444/retry',
            playable: false,
            created_at: '2018-05-18T15:32:54.364Z',
            updated_at: '2018-05-18T15:32:54.364Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/444',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/444/retry',
                method: 'post',
              },
            },
          },
        ],
      },
    ],
    status: {
      icon: 'status_running',
      text: 'running',
      label: 'running',
      group: 'running',
      tooltip: 'running',
      has_details: true,
      details_path: '/gitlab-org/gitlab-shell/pipelines/27#build',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_running-9c635b2419a8e1ec991c993061b89cc5aefc0743bb238ecd0c381e7741a70e8c.png',
    },
    path: '/gitlab-org/gitlab-shell/pipelines/27#build',
    dropdown_path: '/gitlab-org/gitlab-shell/pipelines/27/stage.json?stage=build',
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
            id: 459,
            name: 'jenkins',
            started: '2018-05-18T09:32:20.658Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/459',
            playable: false,
            created_at: '2018-05-18T15:32:55.330Z',
            updated_at: '2018-05-18T15:32:55.330Z',
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
            id: 445,
            name: 'rspec:linux 0 3',
            started: '2018-05-18T07:32:20.655Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/445',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/445/retry',
            playable: false,
            created_at: '2018-05-18T15:32:54.425Z',
            updated_at: '2018-05-18T15:32:54.425Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/445',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/445/retry',
                method: 'post',
              },
            },
          },
          {
            id: 446,
            name: 'rspec:linux 1 3',
            started: '2018-05-18T07:32:20.655Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/446',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/446/retry',
            playable: false,
            created_at: '2018-05-18T15:32:54.506Z',
            updated_at: '2018-05-18T15:32:54.506Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/446',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/446/retry',
                method: 'post',
              },
            },
          },
          {
            id: 447,
            name: 'rspec:linux 2 3',
            started: '2018-05-18T07:32:20.656Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/447',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/447/retry',
            playable: false,
            created_at: '2018-05-18T15:32:54.572Z',
            updated_at: '2018-05-18T15:32:54.572Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/447',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/447/retry',
                method: 'post',
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
          details_path: '/gitlab-org/gitlab-shell/-/jobs/452',
          illustration: {
            image: 'illustrations/empty-state/empty-job-skipped-md.svg',
            size: 'svg-content svg-430',
            title: 'This job does not have a trace.',
          },
          favicon:
            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
          action: {
            icon: 'retry',
            title: 'Retry',
            path: '/gitlab-org/gitlab-shell/-/jobs/452/retry',
            method: 'post',
          },
        },
        jobs: [
          {
            id: 452,
            name: 'rspec:osx',
            started: '2018-05-18T07:32:20.657Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/452',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/452/retry',
            playable: false,
            created_at: '2018-05-18T15:32:54.920Z',
            updated_at: '2018-05-18T15:32:54.920Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/452',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/452/retry',
                method: 'post',
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
            id: 448,
            name: 'rspec:windows 0 3',
            started: '2018-05-18T07:32:20.656Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/448',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/448/retry',
            playable: false,
            created_at: '2018-05-18T15:32:54.639Z',
            updated_at: '2018-05-18T15:32:54.639Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/448',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/448/retry',
                method: 'post',
              },
            },
          },
          {
            id: 449,
            name: 'rspec:windows 1 3',
            started: '2018-05-18T07:32:20.656Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/449',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/449/retry',
            playable: false,
            created_at: '2018-05-18T15:32:54.703Z',
            updated_at: '2018-05-18T15:32:54.703Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/449',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/449/retry',
                method: 'post',
              },
            },
          },
          {
            id: 451,
            name: 'rspec:windows 2 3',
            started: '2018-05-18T07:32:20.657Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/451',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/451/retry',
            playable: false,
            created_at: '2018-05-18T15:32:54.853Z',
            updated_at: '2018-05-18T15:32:54.853Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/451',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/451/retry',
                method: 'post',
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
          details_path: '/gitlab-org/gitlab-shell/-/jobs/453',
          illustration: {
            image: 'illustrations/empty-state/empty-job-skipped-md.svg',
            size: 'svg-content svg-430',
            title: 'This job does not have a trace.',
          },
          favicon:
            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
          action: {
            icon: 'retry',
            title: 'Retry',
            path: '/gitlab-org/gitlab-shell/-/jobs/453/retry',
            method: 'post',
          },
        },
        jobs: [
          {
            id: 453,
            name: 'spinach:linux',
            started: '2018-05-18T07:32:20.657Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/453',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/453/retry',
            playable: false,
            created_at: '2018-05-18T15:32:54.993Z',
            updated_at: '2018-05-18T15:32:54.993Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/453',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/453/retry',
                method: 'post',
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
          details_path: '/gitlab-org/gitlab-shell/-/jobs/454',
          illustration: {
            image: 'illustrations/empty-state/empty-job-skipped-md.svg',
            size: 'svg-content svg-430',
            title: 'This job does not have a trace.',
          },
          favicon:
            '/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
          action: {
            icon: 'retry',
            title: 'Retry',
            path: '/gitlab-org/gitlab-shell/-/jobs/454/retry',
            method: 'post',
          },
        },
        jobs: [
          {
            id: 454,
            name: 'spinach:osx',
            started: '2018-05-18T07:32:20.657Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/454',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/454/retry',
            playable: false,
            created_at: '2018-05-18T15:32:55.053Z',
            updated_at: '2018-05-18T15:32:55.053Z',
            status: {
              icon: 'status_warning',
              text: 'failed',
              label: 'failed (allowed to fail)',
              group: 'failed-with-warnings',
              tooltip: 'failed - (unknown failure) (allowed to fail)',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/454',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/454/retry',
                method: 'post',
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
      details_path: '/gitlab-org/gitlab-shell/pipelines/27#test',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    path: '/gitlab-org/gitlab-shell/pipelines/27#test',
    dropdown_path: '/gitlab-org/gitlab-shell/pipelines/27/stage.json?stage=test',
  },
  {
    name: 'deploy',
    title: 'deploy: running',
    groups: [
      {
        name: 'production',
        size: 1,
        status: {
          icon: 'status_created',
          text: 'created',
          label: 'created',
          group: 'created',
          tooltip: 'created',
          has_details: true,
          details_path: '/gitlab-org/gitlab-shell/-/jobs/457',
          illustration: {
            image: 'illustrations/empty-state/empty-job-not-triggered-md.svg',
            size: '',
            title: 'This job has not been triggered yet',
            content:
              'This job depends on upstream jobs that need to succeed in order for this job to be triggered',
          },
          favicon:
            '/assets/ci_favicons/favicon_status_created-4b975aa976d24e5a3ea7cd9a5713e6ce2cd9afd08b910415e96675de35f64955.png',
          action: {
            icon: 'cancel',
            title: 'Cancel',
            path: '/gitlab-org/gitlab-shell/-/jobs/457/cancel',
            method: 'post',
          },
        },
        jobs: [
          {
            id: 457,
            name: 'production',
            started: false,
            build_path: '/gitlab-org/gitlab-shell/-/jobs/457',
            cancel_path: '/gitlab-org/gitlab-shell/-/jobs/457/cancel',
            playable: false,
            created_at: '2018-05-18T15:32:55.259Z',
            updated_at: '2018-09-28T11:09:57.454Z',
            status: {
              icon: 'status_created',
              text: 'created',
              label: 'created',
              group: 'created',
              tooltip: 'created',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/457',
              illustration: {
                image: 'illustrations/empty-state/empty-job-not-triggered-md.svg',
                size: '',
                title: 'This job has not been triggered yet',
                content:
                  'This job depends on upstream jobs that need to succeed in order for this job to be triggered',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_created-4b975aa976d24e5a3ea7cd9a5713e6ce2cd9afd08b910415e96675de35f64955.png',
              action: {
                icon: 'cancel',
                title: 'Cancel',
                path: '/gitlab-org/gitlab-shell/-/jobs/457/cancel',
                method: 'post',
              },
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
          details_path: '/gitlab-org/gitlab-shell/-/jobs/455',
          illustration: {
            image: 'illustrations/empty-state/empty-job-skipped-md.svg',
            size: 'svg-content svg-430',
            title: 'This job does not have a trace.',
          },
          favicon:
            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
          action: {
            icon: 'retry',
            title: 'Retry',
            path: '/gitlab-org/gitlab-shell/-/jobs/455/retry',
            method: 'post',
          },
        },
        jobs: [
          {
            id: 455,
            name: 'staging',
            started: '2018-05-18T09:32:20.658Z',
            build_path: '/gitlab-org/gitlab-shell/-/jobs/455',
            retry_path: '/gitlab-org/gitlab-shell/-/jobs/455/retry',
            playable: false,
            created_at: '2018-05-18T15:32:55.119Z',
            updated_at: '2018-05-18T15:32:55.119Z',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/455',
              illustration: {
                image: 'illustrations/empty-state/empty-job-skipped-md.svg',
                size: 'svg-content svg-430',
                title: 'This job does not have a trace.',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
              action: {
                icon: 'retry',
                title: 'Retry',
                path: '/gitlab-org/gitlab-shell/-/jobs/455/retry',
                method: 'post',
              },
            },
          },
        ],
      },
      {
        name: 'stop staging',
        size: 1,
        status: {
          icon: 'status_created',
          text: 'created',
          label: 'created',
          group: 'created',
          tooltip: 'created',
          has_details: true,
          details_path: '/gitlab-org/gitlab-shell/-/jobs/456',
          illustration: {
            image: 'illustrations/empty-state/empty-job-not-triggered-md.svg',
            size: '',
            title: 'This job has not been triggered yet',
            content:
              'This job depends on upstream jobs that need to succeed in order for this job to be triggered',
          },
          favicon:
            '/assets/ci_favicons/favicon_status_created-4b975aa976d24e5a3ea7cd9a5713e6ce2cd9afd08b910415e96675de35f64955.png',
          action: {
            icon: 'cancel',
            title: 'Cancel',
            path: '/gitlab-org/gitlab-shell/-/jobs/456/cancel',
            method: 'post',
          },
        },
        jobs: [
          {
            id: 456,
            name: 'stop staging',
            started: false,
            build_path: '/gitlab-org/gitlab-shell/-/jobs/456',
            cancel_path: '/gitlab-org/gitlab-shell/-/jobs/456/cancel',
            playable: false,
            created_at: '2018-05-18T15:32:55.205Z',
            updated_at: '2018-09-28T11:09:57.396Z',
            status: {
              icon: 'status_created',
              text: 'created',
              label: 'created',
              group: 'created',
              tooltip: 'created',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/456',
              illustration: {
                image: 'illustrations/empty-state/empty-job-not-triggered-md.svg',
                size: '',
                title: 'This job has not been triggered yet',
                content:
                  'This job depends on upstream jobs that need to succeed in order for this job to be triggered',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_created-4b975aa976d24e5a3ea7cd9a5713e6ce2cd9afd08b910415e96675de35f64955.png',
              action: {
                icon: 'cancel',
                title: 'Cancel',
                path: '/gitlab-org/gitlab-shell/-/jobs/456/cancel',
                method: 'post',
              },
            },
          },
        ],
      },
    ],
    status: {
      icon: 'status_running',
      text: 'running',
      label: 'running',
      group: 'running',
      tooltip: 'running',
      has_details: true,
      details_path: '/gitlab-org/gitlab-shell/pipelines/27#deploy',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_running-9c635b2419a8e1ec991c993061b89cc5aefc0743bb238ecd0c381e7741a70e8c.png',
    },
    path: '/gitlab-org/gitlab-shell/pipelines/27#deploy',
    dropdown_path: '/gitlab-org/gitlab-shell/pipelines/27/stage.json?stage=deploy',
  },
  {
    name: 'notify',
    title: 'notify: manual action',
    groups: [
      {
        name: 'slack',
        size: 1,
        status: {
          icon: 'status_manual',
          text: 'manual',
          label: 'manual play action',
          group: 'manual',
          tooltip: 'manual action',
          has_details: true,
          details_path: '/gitlab-org/gitlab-shell/-/jobs/458',
          illustration: {
            image: 'illustrations/empty-state/empty-job-manual-md.svg',
            size: '',
            title: 'This job requires a manual action',
            content:
              'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
          },
          favicon:
            '/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
          action: {
            icon: 'play',
            title: 'Play',
            path: '/gitlab-org/gitlab-shell/-/jobs/458/play',
            method: 'post',
          },
        },
        jobs: [
          {
            id: 458,
            name: 'slack',
            started: null,
            build_path: '/gitlab-org/gitlab-shell/-/jobs/458',
            play_path: '/gitlab-org/gitlab-shell/-/jobs/458/play',
            playable: true,
            created_at: '2018-05-18T15:32:55.303Z',
            updated_at: '2018-05-18T15:34:08.535Z',
            status: {
              icon: 'status_manual',
              text: 'manual',
              label: 'manual play action',
              group: 'manual',
              tooltip: 'manual action',
              has_details: true,
              details_path: '/gitlab-org/gitlab-shell/-/jobs/458',
              illustration: {
                image: 'illustrations/empty-state/empty-job-manual-md.svg',
                size: '',
                title: 'This job requires a manual action',
                content:
                  'This job depends on a user to trigger its process. Often they are used to deploy code to production environments',
              },
              favicon:
                '/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
              action: {
                icon: 'play',
                title: 'Play',
                path: '/gitlab-org/gitlab-shell/-/jobs/458/play',
                method: 'post',
              },
            },
          },
        ],
      },
    ],
    status: {
      icon: 'status_manual',
      text: 'manual',
      label: 'manual action',
      group: 'manual',
      tooltip: 'manual action',
      has_details: true,
      details_path: '/gitlab-org/gitlab-shell/pipelines/27#notify',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_manual-829a0804612cef47d9efc1618dba38325483657c847dba0546c3b9f0295bb36c.png',
    },
    path: '/gitlab-org/gitlab-shell/pipelines/27#notify',
    dropdown_path: '/gitlab-org/gitlab-shell/pipelines/27/stage.json?stage=notify',
  },
];

export const statuses = {
  success: 'SUCCESS',
  failed: 'FAILED',
  canceled: 'CANCELED',
  pending: 'PENDING',
  running: 'RUNNING',
};

export default {
  id: 4757,
  artifact: {
    locked: false,
  },
  name: 'test',
  stage: 'build',
  build_path: '/root/ci-mock/-/jobs/4757',
  retry_path: '/root/ci-mock/-/jobs/4757/retry',
  cancel_path: '/root/ci-mock/-/jobs/4757/cancel',
  new_issue_path: '/root/ci-mock/issues/new',
  playable: false,
  complete: true,
  created_at: threeWeeksAgo.toISOString(),
  updated_at: threeWeeksAgo.toISOString(),
  finished_at: threeWeeksAgo.toISOString(),
  queued_duration: 9.54,
  status: {
    icon: 'status_success',
    text: 'passed',
    label: 'passed',
    group: 'success',
    has_details: true,
    details_path: `${TEST_HOST}/root/ci-mock/-/jobs/4757`,
    favicon:
      '/assets/ci_favicons/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.png',
    action: {
      icon: 'retry',
      title: 'Retry',
      path: '/root/ci-mock/-/jobs/4757/retry',
      method: 'post',
    },
  },
  coverage: 20,
  erased_at: threeWeeksAgo.toISOString(),
  erased: false,
  duration: 6.785563,
  tags: ['tag'],
  user: {
    name: 'Root',
    username: 'root',
    id: 1,
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
    web_url: 'http://localhost:3000/root',
  },
  erase_path: '/root/ci-mock/-/jobs/4757/erase',
  artifacts: [null],
  annotations: [],
  runner: {
    id: 1,
    short_sha: 'ABCDEFGH',
    description: 'local ci runner',
    edit_path: '/root/ci-mock/runners/1/edit',
  },
  pipeline: {
    id: 140,
    user: {
      name: 'Root',
      username: 'root',
      id: 1,
      state: 'active',
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      web_url: 'http://localhost:3000/root',
    },
    active: false,
    coverage: null,
    source: 'unknown',
    created_at: '2017-05-24T09:59:58.634Z',
    updated_at: '2017-06-01T17:32:00.062Z',
    path: '/root/ci-mock/pipelines/140',
    flags: {
      latest: true,
      stuck: false,
      yaml_errors: false,
      retryable: false,
      cancelable: false,
    },
    details: {
      status: {
        icon: 'status_success',
        text: 'passed',
        label: 'passed',
        group: 'success',
        has_details: true,
        details_path: '/root/ci-mock/pipelines/140',
        favicon:
          '/assets/ci_favicons/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.png',
      },
      duration: 6,
      finished_at: '2017-06-01T17:32:00.042Z',
      stages: [
        {
          dropdown_path: '/jashkenas/underscore/pipelines/16/stage.json?stage=build',
          name: 'build',
          path: '/jashkenas/underscore/pipelines/16#build',
          status: {
            icon: 'status_success',
            text: 'passed',
            label: 'passed',
            group: 'success',
            tooltip: 'passed',
          },
          title: 'build: passed',
        },
        {
          dropdown_path: '/jashkenas/underscore/pipelines/16/stage.json?stage=test',
          name: 'test',
          path: '/jashkenas/underscore/pipelines/16#test',
          status: {
            icon: 'status_warning',
            text: 'passed',
            label: 'passed with warnings',
            group: 'success-with-warnings',
          },
          title: 'test: passed with warnings',
        },
      ],
    },
    ref: {
      name: 'abc',
      path: '/root/ci-mock/commits/abc',
      tag: false,
      branch: true,
    },
    commit: {
      id: 'c58647773a6b5faf066d4ad6ff2c9fbba5f180f6',
      short_id: 'c5864777',
      title: 'Add new file',
      created_at: '2017-05-24T10:59:52.000+01:00',
      parent_ids: ['798e5f902592192afaba73f4668ae30e56eae492'],
      message: 'Add new file',
      author_name: 'Root',
      author_email: 'admin@example.com',
      authored_date: '2017-05-24T10:59:52.000+01:00',
      committer_name: 'Root',
      committer_email: 'admin@example.com',
      committed_date: '2017-05-24T10:59:52.000+01:00',
      author: {
        name: 'Root',
        username: 'root',
        id: 1,
        state: 'active',
        avatar_url:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
        web_url: 'http://localhost:3000/root',
      },
      author_gravatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
      commit_url:
        'http://localhost:3000/root/ci-mock/commit/c58647773a6b5faf066d4ad6ff2c9fbba5f180f6',
      commit_path: '/root/ci-mock/commit/c58647773a6b5faf066d4ad6ff2c9fbba5f180f6',
    },
  },
  metadata: {
    timeout_human_readable: '1m 40s',
    timeout_source: 'runner',
  },
  merge_request: {
    iid: 2,
    path: '/root/ci-mock/merge_requests/2',
  },
  raw_path: '/root/ci-mock/builds/4757/raw',
  has_trace: true,
};

export const failedJobStatus = {
  icon: 'status_warning',
  text: 'failed',
  label: 'failed (allowed to fail)',
  group: 'failed-with-warnings',
  tooltip: 'failed - (unknown failure) (allowed to fail)',
  has_details: true,
  details_path: '/gitlab-org/gitlab-shell/-/jobs/454',
  illustration: {
    image: 'illustrations/empty-state/empty-job-skipped-md.svg',
    size: 'svg-content svg-430',
    title: 'This job does not have a trace.',
  },
  favicon:
    '/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
  action: {
    icon: 'retry',
    title: 'Retry',
    path: '/gitlab-org/gitlab-shell/-/jobs/454/retry',
    method: 'post',
  },
};

export const jobsInStage = {
  name: 'build',
  title: 'build: running',
  latest_statuses: [
    {
      id: 1180,
      name: 'build:linux',
      started: false,
      build_path: '/gitlab-org/gitlab-shell/-/jobs/1180',
      cancel_path: '/gitlab-org/gitlab-shell/-/jobs/1180/cancel',
      playable: false,
      created_at: '2018-09-28T11:09:57.229Z',
      updated_at: '2018-09-28T11:09:57.503Z',
      status: {
        icon: 'status_pending',
        text: 'pending',
        label: 'pending',
        group: 'pending',
        tooltip: 'pending',
        has_details: true,
        details_path: '/gitlab-org/gitlab-shell/-/jobs/1180',
        illustration: {
          image: 'illustrations/empty-state/empty-job-pending-md.svg',
          size: 'svg-content svg-430',
          title: 'This job has not started yet',
          content: 'This job is in pending state and is waiting to be picked by a runner',
        },
        favicon:
          '/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png',
        action: {
          icon: 'cancel',
          title: 'Cancel',
          path: '/gitlab-org/gitlab-shell/-/jobs/1180/cancel',
          method: 'post',
        },
      },
    },
    {
      id: 444,
      name: 'build:osx',
      started: '2018-05-18T05:32:20.655Z',
      build_path: '/gitlab-org/gitlab-shell/-/jobs/444',
      retry_path: '/gitlab-org/gitlab-shell/-/jobs/444/retry',
      playable: false,
      created_at: '2018-05-18T15:32:54.364Z',
      updated_at: '2018-05-18T15:32:54.364Z',
      status: {
        icon: 'status_success',
        text: 'passed',
        label: 'passed',
        group: 'success',
        tooltip: 'passed',
        has_details: true,
        details_path: '/gitlab-org/gitlab-shell/-/jobs/444',
        illustration: {
          image: 'illustrations/empty-state/empty-job-skipped-md.svg',
          size: 'svg-content svg-430',
          title: 'This job does not have a trace.',
        },
        favicon:
          '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
        action: {
          icon: 'retry',
          title: 'Retry',
          path: '/gitlab-org/gitlab-shell/-/jobs/444/retry',
          method: 'post',
        },
      },
    },
  ],
  retried: [
    {
      id: 443,
      name: 'build:linux',
      started: '2018-05-18T06:32:20.655Z',
      build_path: '/gitlab-org/gitlab-shell/-/jobs/443',
      retry_path: '/gitlab-org/gitlab-shell/-/jobs/443/retry',
      playable: false,
      created_at: '2018-05-18T15:32:54.296Z',
      updated_at: '2018-05-18T15:32:54.296Z',
      status: {
        icon: 'status_success',
        text: 'passed',
        label: 'passed',
        group: 'success',
        tooltip: 'passed (retried)',
        has_details: true,
        details_path: '/gitlab-org/gitlab-shell/-/jobs/443',
        illustration: {
          image: 'illustrations/empty-state/empty-job-skipped-md.svg',
          size: 'svg-content svg-430',
          title: 'This job does not have a trace.',
        },
        favicon:
          '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
        action: {
          icon: 'retry',
          title: 'Retry',
          path: '/gitlab-org/gitlab-shell/-/jobs/443/retry',
          method: 'post',
        },
      },
    },
  ],
  status: {
    icon: 'status_running',
    text: 'running',
    label: 'running',
    group: 'running',
    tooltip: 'running',
    has_details: true,
    details_path: '/gitlab-org/gitlab-shell/pipelines/27#build',
    illustration: null,
    favicon:
      '/assets/ci_favicons/favicon_status_running-9c635b2419a8e1ec991c993061b89cc5aefc0743bb238ecd0c381e7741a70e8c.png',
  },
  path: '/gitlab-org/gitlab-shell/pipelines/27#build',
  dropdown_path: '/gitlab-org/gitlab-shell/pipelines/27/stage.json?stage=build',
};

export const mockPipelineWithoutMR = {
  id: 28029444,
  details: {
    status: {
      details_path: '/gitlab-org/gitlab-foss/pipelines/28029444',
      group: 'success',
      has_details: true,
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      tooltip: 'passed',
    },
  },
  path: 'pipeline/28029444',
  ref: {
    name: 'test-branch',
  },
};

export const mockPipelineWithoutRef = {
  ...mockPipelineWithoutMR,
  ref: null,
};

export const mockPipelineWithAttachedMR = {
  id: 28029444,
  details: {
    status: {
      details_path: '/gitlab-org/gitlab-foss/pipelines/28029444',
      group: 'success',
      has_details: true,
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      tooltip: 'passed',
    },
  },
  path: 'pipeline/28029444',
  flags: {
    merge_request_pipeline: true,
    detached_merge_request_pipeline: false,
  },
  merge_request: {
    iid: 1234,
    path: '/root/detached-merge-request-pipelines/-/merge_requests/1',
    title: 'Update README.md',
    source_branch: 'feature-1234',
    source_branch_path: '/root/detached-merge-request-pipelines/branches/feature-1234',
    target_branch: 'main',
    target_branch_path: '/root/detached-merge-request-pipelines/branches/main',
  },
  ref: {
    name: 'test-branch',
  },
};

export const mockPipelineDetached = {
  id: 28029444,
  details: {
    status: {
      details_path: '/gitlab-org/gitlab-foss/pipelines/28029444',
      group: 'success',
      has_details: true,
      icon: 'status_success',
      label: 'passed',
      text: 'passed',
      tooltip: 'passed',
    },
  },
  path: 'pipeline/28029444',
  flags: {
    merge_request_pipeline: false,
    detached_merge_request_pipeline: true,
  },
  merge_request: {
    iid: 1234,
    path: '/root/detached-merge-request-pipelines/-/merge_requests/1',
    title: 'Update README.md',
    source_branch: 'feature-1234',
    source_branch_path: '/root/detached-merge-request-pipelines/branches/feature-1234',
    target_branch: 'main',
    target_branch_path: '/root/detached-merge-request-pipelines/branches/main',
  },
  ref: {
    name: 'test-branch',
  },
};

export const CIJobConnectionIncomingCache = {
  __typename: 'CiJobConnection',
  pageInfo: {
    __typename: 'PageInfo',
    endCursor: 'eyJpZCI6IjIwNTEifQ',
    hasNextPage: true,
    hasPreviousPage: false,
    startCursor: 'eyJpZCI6IjIxNzMifQ',
  },
  nodes: [
    { __ref: 'CiJob:gid://gitlab/Ci::Build/2057' },
    { __ref: 'CiJob:gid://gitlab/Ci::Build/2056' },
    { __ref: 'CiJob:gid://gitlab/Ci::Build/2051' },
  ],
};

export const CIJobConnectionIncomingCacheRunningStatus = {
  __typename: 'CiJobConnection',
  pageInfo: {
    __typename: 'PageInfo',
    endCursor: 'eyJpZCI6IjIwNTEifQ',
    hasNextPage: true,
    hasPreviousPage: false,
    startCursor: 'eyJpZCI6IjIxNzMifQ',
  },
  nodes: [
    { __ref: 'CiJob:gid://gitlab/Ci::Build/2000' },
    { __ref: 'CiJob:gid://gitlab/Ci::Build/2001' },
    { __ref: 'CiJob:gid://gitlab/Ci::Build/2002' },
  ],
};

export const CIJobConnectionExistingCache = {
  pageInfo: {
    __typename: 'PageInfo',
    endCursor: 'eyJpZCI6IjIwNTEifQ',
    hasNextPage: true,
    hasPreviousPage: false,
    startCursor: 'eyJpZCI6IjIxNzMifQ',
  },
  nodes: [
    { __ref: 'CiJob:gid://gitlab/Ci::Build/2100' },
    { __ref: 'CiJob:gid://gitlab/Ci::Build/2101' },
    { __ref: 'CiJob:gid://gitlab/Ci::Build/2102' },
  ],
  statuses: 'PENDING',
};

export const mockFailedSearchToken = {
  type: TOKEN_TYPE_STATUS,
  value: { data: 'FAILED', operator: '=' },
};

export const retryMutationResponse = {
  data: {
    jobRetry: {
      job: {
        __typename: 'CiJob',
        id: '"gid://gitlab/Ci::Build/1985"',
        detailedStatus: {
          detailsPath: '/root/project/-/jobs/1985',
          id: 'pending-1985-1985',
          __typename: 'DetailedStatus',
        },
      },
      errors: [],
      __typename: 'JobRetryPayload',
    },
  },
};

export const playMutationResponse = {
  data: {
    jobPlay: {
      job: {
        __typename: 'CiJob',
        id: '"gid://gitlab/Ci::Build/1986"',
        detailedStatus: {
          detailsPath: '/root/project/-/jobs/1986',
          id: 'pending-1986-1986',
          __typename: 'DetailedStatus',
        },
      },
      errors: [],
      __typename: 'JobRetryPayload',
    },
  },
};

export const cancelMutationResponse = {
  data: {
    jobCancel: {
      job: {
        __typename: 'CiJob',
        id: '"gid://gitlab/Ci::Build/1987"',
        detailedStatus: {
          detailsPath: '/root/project/-/jobs/1987',
          id: 'pending-1987-1987',
          __typename: 'DetailedStatus',
        },
      },
      errors: [],
      __typename: 'JobRetryPayload',
    },
  },
};

export const unscheduleMutationResponse = {
  data: {
    jobUnschedule: {
      job: {
        __typename: 'CiJob',
        id: '"gid://gitlab/Ci::Build/1988"',
        detailedStatus: {
          detailsPath: '/root/project/-/jobs/1988',
          id: 'pending-1988-1988',
          __typename: 'DetailedStatus',
        },
      },
      errors: [],
      __typename: 'JobRetryPayload',
    },
  },
};

export const mockJobLog = [
  { offset: 0, content: [{ text: 'Running with gitlab-runner 15.0.0 (febb2a09)' }], lineNumber: 0 },
  { offset: 54, content: [{ text: '  on colima-docker EwM9WzgD' }], lineNumber: 1 },
  {
    isClosed: false,
    isHeader: true,
    line: {
      offset: 91,
      content: [{ text: 'Resolving secrets', style: 'term-fg-l-cyan term-bold' }],
      section: 'resolve-secrets',
      section_header: true,
      lineNumber: 2,
      section_duration: '00:00',
    },
    lines: [],
  },
  {
    isClosed: false,
    isHeader: true,
    line: {
      offset: 218,
      content: [{ text: 'Preparing the "docker" executor', style: 'term-fg-l-cyan term-bold' }],
      section: 'prepare-executor',
      section_header: true,
      lineNumber: 4,
      section_duration: '00:01',
    },
    lines: [
      {
        offset: 317,
        content: [{ text: 'Using Docker executor with image ruby:2.7 ...' }],
        section: 'prepare-executor',
        lineNumber: 5,
      },
      {
        offset: 372,
        content: [{ text: 'Pulling docker image ruby:2.7 ...' }],
        section: 'prepare-executor',
        lineNumber: 6,
      },
      {
        offset: 415,
        content: [
          {
            text: 'Using docker image sha256:55106bf6ba7f452c38d01ea760affc6ceb67d4b60068ffadab98d1b7b007668c for ruby:2.7 with digest ruby@sha256:23d08a4bae1a12ee3fce017f83204fcf9a02243443e4a516e65e5ff73810a449 ...',
          },
        ],
        section: 'prepare-executor',
        lineNumber: 7,
      },
    ],
  },
  {
    isClosed: false,
    isHeader: true,
    line: {
      offset: 665,
      content: [{ text: 'Preparing environment', style: 'term-fg-l-cyan term-bold' }],
      section: 'prepare-script',
      section_header: true,
      lineNumber: 9,
      section_duration: '00:01',
    },
    lines: [
      {
        offset: 752,
        content: [
          { text: 'Running on runner-ewm9wzgd-project-20-concurrent-0 via 8ea689ec6969...' },
        ],
        section: 'prepare-script',
        lineNumber: 10,
      },
    ],
  },
  {
    isClosed: false,
    isHeader: true,
    line: {
      offset: 865,
      content: [{ text: 'Getting source from Git repository', style: 'term-fg-l-cyan term-bold' }],
      section: 'get-sources',
      section_header: true,
      lineNumber: 12,
      section_duration: '00:01',
    },
    lines: [
      {
        offset: 962,
        content: [
          {
            text: 'Fetching changes with git depth set to 20...',
            style: 'term-fg-l-green term-bold',
          },
        ],
        section: 'get-sources',
        lineNumber: 13,
      },
      {
        offset: 1019,
        content: [
          { text: 'Reinitialized existing Git repository in /builds/root/ci-project/.git/' },
        ],
        section: 'get-sources',
        lineNumber: 14,
      },
      {
        offset: 1090,
        content: [{ text: 'Checking out e0f63d76 as main...', style: 'term-fg-l-green term-bold' }],
        section: 'get-sources',
        lineNumber: 15,
      },
      {
        offset: 1136,
        content: [{ text: 'Skipping Git submodules setup', style: 'term-fg-l-green term-bold' }],
        section: 'get-sources',
        lineNumber: 16,
      },
    ],
  },
  {
    isClosed: false,
    isHeader: true,
    line: {
      offset: 1217,
      content: [
        {
          text: 'Executing "step_script" stage of the job script',
          style: 'term-fg-l-cyan term-bold',
        },
      ],
      section: 'step-script',
      section_header: true,
      lineNumber: 18,
      section_duration: '00:00',
    },
    lines: [
      {
        offset: 1327,
        content: [
          {
            text: 'Using docker image sha256:55106bf6ba7f452c38d01ea760affc6ceb67d4b60068ffadab98d1b7b007668c for ruby:2.7 with digest ruby@sha256:23d08a4bae1a12ee3fce017f83204fcf9a02243443e4a516e65e5ff73810a449 ...',
          },
        ],
        section: 'step-script',
        lineNumber: 19,
      },
      {
        offset: 1533,
        content: [{ text: '$ echo "82.71"', style: 'term-fg-l-green term-bold' }],
        section: 'step-script',
        lineNumber: 20,
      },
      { offset: 1560, content: [{ text: '82.71' }], section: 'step-script', lineNumber: 21 },
    ],
  },
  {
    offset: 1605,
    content: [{ text: 'Job succeeded', style: 'term-fg-l-green term-bold' }],
    lineNumber: 23,
  },
];

export const testSummaryData = {
  total: {
    time: 0.001,
    count: 1,
    success: 1,
    failed: 0,
    skipped: 0,
    error: 0,
    suite_error: null,
  },
  test_suites: [
    {
      name: 'javascript',
      total_time: 0.001,
      total_count: 1,
      success_count: 1,
      failed_count: 0,
      skipped_count: 0,
      error_count: 0,
      build_ids: [3633],
      suite_error: null,
    },
  ],
};

export const testSummaryDataWithFailures = {
  total: {
    time: 0.001,
    count: 2,
    success: 1,
    failed: 1,
    skipped: 0,
    error: 0,
    suite_error: null,
  },
  test_suites: [
    {
      name: 'javascript',
      total_time: 0.001,
      total_count: 2,
      success_count: 1,
      failed_count: 1,
      skipped_count: 0,
      error_count: 0,
      build_ids: [3633],
      suite_error: null,
    },
  ],
};
