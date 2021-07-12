import { GlLoadingIcon } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import { getJSONFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import EmptyState from '~/jobs/components/empty_state.vue';
import EnvironmentsBlock from '~/jobs/components/environments_block.vue';
import ErasedBlock from '~/jobs/components/erased_block.vue';
import JobApp from '~/jobs/components/job_app.vue';
import Sidebar from '~/jobs/components/sidebar.vue';
import StuckBlock from '~/jobs/components/stuck_block.vue';
import UnmetPrerequisitesBlock from '~/jobs/components/unmet_prerequisites_block.vue';
import createStore from '~/jobs/store';
import axios from '~/lib/utils/axios_utils';
import job from '../mock_data';

describe('Job App', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  const delayedJobFixture = getJSONFixture('jobs/delayed.json');

  let store;
  let wrapper;
  let mock;
  let origGon;

  const initSettings = {
    endpoint: `${TEST_HOST}jobs/123.json`,
    pagePath: `${TEST_HOST}jobs/123`,
    logState:
      'eyJvZmZzZXQiOjE3NDUxLCJuX29wZW5fdGFncyI6MCwiZmdfY29sb3IiOm51bGwsImJnX2NvbG9yIjpudWxsLCJzdHlsZV9tYXNrIjowfQ%3D%3D',
  };

  const props = {
    artifactHelpUrl: 'help/artifact',
    deploymentHelpUrl: 'help/deployment',
    codeQualityHelpPath: '/help/code_quality',
    runnerSettingsUrl: 'settings/ci-cd/runners',
    terminalPath: 'jobs/123/terminal',
    projectPath: 'user-name/project-name',
    subscriptionsMoreMinutesUrl: 'https://customers.gitlab.com/buy_pipeline_minutes',
  };

  const createComponent = () => {
    wrapper = mount(JobApp, { propsData: { ...props }, store });
  };

  const setupAndMount = ({ jobData = {}, traceData = {} } = {}) => {
    mock.onGet(initSettings.endpoint).replyOnce(200, { ...job, ...jobData });
    mock.onGet(`${initSettings.pagePath}/trace.json`).reply(200, traceData);

    const asyncInit = store.dispatch('init', initSettings);

    createComponent();

    return asyncInit
      .then(() => {
        jest.runOnlyPendingTimers();
      })
      .then(() => axios.waitForAll())
      .then(() => wrapper.vm.$nextTick());
  };

  const findLoadingComponent = () => wrapper.find(GlLoadingIcon);
  const findSidebar = () => wrapper.find(Sidebar);
  const findJobContent = () => wrapper.find('[data-testid="job-content"');
  const findStuckBlockComponent = () => wrapper.find(StuckBlock);
  const findStuckBlockWithTags = () => wrapper.find('[data-testid="job-stuck-with-tags"');
  const findStuckBlockNoActiveRunners = () =>
    wrapper.find('[data-testid="job-stuck-no-active-runners"');
  const findFailedJobComponent = () => wrapper.find(UnmetPrerequisitesBlock);
  const findEnvironmentsBlockComponent = () => wrapper.find(EnvironmentsBlock);
  const findErasedBlock = () => wrapper.find(ErasedBlock);
  const findArchivedJob = () => wrapper.find('[data-testid="archived-job"]');
  const findEmptyState = () => wrapper.find(EmptyState);
  const findJobNewIssueLink = () => wrapper.find('[data-testid="job-new-issue"]');
  const findJobEmptyStateTitle = () => wrapper.find('[data-testid="job-empty-state-title"]');
  const findJobTraceScrollTop = () => wrapper.find('[data-testid="job-controller-scroll-top"]');
  const findJobTraceScrollBottom = () =>
    wrapper.find('[data-testid="job-controller-scroll-bottom"]');
  const findJobTraceController = () => wrapper.find('[data-testid="job-raw-link-controller"]');
  const findJobTraceEraseLink = () => wrapper.find('[data-testid="job-log-erase-link"]');

  beforeEach(() => {
    mock = new MockAdapter(axios);
    store = createStore();

    origGon = window.gon;

    window.gon = { features: { infinitelyCollapsibleSections: false } }; // NOTE: All of this passes with the feature flag
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();

    window.gon = origGon;
  });

  describe('while loading', () => {
    beforeEach(() => {
      store.state.isLoading = true;
      createComponent();
    });

    it('renders loading icon', () => {
      expect(findLoadingComponent().exists()).toBe(true);
      expect(findSidebar().exists()).toBe(false);
      expect(findJobContent().exists()).toBe(false);
    });
  });

  describe('with successful request', () => {
    describe('Header section', () => {
      describe('job callout message', () => {
        it('should not render the reason when reason is absent', () =>
          setupAndMount().then(() => {
            expect(wrapper.vm.shouldRenderCalloutMessage).toBe(false);
          }));

        it('should render the reason when reason is present', () =>
          setupAndMount({
            jobData: {
              callout_message: 'There is an unkown failure, please try again',
            },
          }).then(() => {
            expect(wrapper.vm.shouldRenderCalloutMessage).toBe(true);
          }));
      });

      describe('triggered job', () => {
        beforeEach(() => {
          const aYearAgo = new Date();
          aYearAgo.setFullYear(aYearAgo.getFullYear() - 1);

          return setupAndMount({ jobData: { started: aYearAgo.toISOString() } });
        });

        it('should render provided job information', () => {
          expect(wrapper.find('.header-main-content').text().replace(/\s+/g, ' ').trim()).toContain(
            'passed Job #4757 triggered 1 year ago by Root',
          );
        });

        it('should render new issue link', () => {
          expect(findJobNewIssueLink().attributes('href')).toEqual(job.new_issue_path);
        });
      });

      describe('created job', () => {
        it('should render created key', () =>
          setupAndMount().then(() => {
            expect(
              wrapper.find('.header-main-content').text().replace(/\s+/g, ' ').trim(),
            ).toContain('passed Job #4757 created 3 weeks ago by Root');
          }));
      });
    });

    describe('stuck block', () => {
      describe('without active runners available', () => {
        it('renders stuck block when there are no runners', () =>
          setupAndMount({
            jobData: {
              status: {
                group: 'pending',
                icon: 'status_pending',
                label: 'pending',
                text: 'pending',
                details_path: 'path',
              },
              stuck: true,
              runners: {
                available: false,
                online: false,
              },
              tags: [],
            },
          }).then(() => {
            expect(findStuckBlockComponent().exists()).toBe(true);
            expect(findStuckBlockNoActiveRunners().exists()).toBe(true);
          }));
      });

      describe('when available runners can not run specified tag', () => {
        it('renders tags in stuck block when there are no runners', () =>
          setupAndMount({
            jobData: {
              status: {
                group: 'pending',
                icon: 'status_pending',
                label: 'pending',
                text: 'pending',
                details_path: 'path',
              },
              stuck: true,
              runners: {
                available: false,
                online: false,
              },
            },
          }).then(() => {
            expect(findStuckBlockComponent().text()).toContain(job.tags[0]);
            expect(findStuckBlockWithTags().exists()).toBe(true);
          }));
      });

      describe('when runners are offline and build has tags', () => {
        it('renders message about job being stuck because of no runners with the specified tags', () =>
          setupAndMount({
            jobData: {
              status: {
                group: 'pending',
                icon: 'status_pending',
                label: 'pending',
                text: 'pending',
                details_path: 'path',
              },
              stuck: true,
              runners: {
                available: true,
                online: true,
              },
            },
          }).then(() => {
            expect(findStuckBlockComponent().text()).toContain(job.tags[0]);
            expect(findStuckBlockWithTags().exists()).toBe(true);
          }));
      });

      it('does not renders stuck block when there are no runners', () =>
        setupAndMount({
          jobData: {
            runners: { available: true },
          },
        }).then(() => {
          expect(findStuckBlockComponent().exists()).toBe(false);
        }));
    });

    describe('unmet prerequisites block', () => {
      it('renders unmet prerequisites block when there is an unmet prerequisites failure', () =>
        setupAndMount({
          jobData: {
            status: {
              group: 'failed',
              icon: 'status_failed',
              label: 'failed',
              text: 'failed',
              details_path: 'path',
              illustration: {
                content: 'Retry this job in order to create the necessary resources.',
                image: 'path',
                size: 'svg-430',
                title: 'Failed to create resources',
              },
            },
            failure_reason: 'unmet_prerequisites',
            has_trace: false,
            runners: {
              available: true,
            },
            tags: [],
          },
        }).then(() => {
          expect(findFailedJobComponent().exists()).toBe(true);
        }));
    });

    describe('environments block', () => {
      it('renders environment block when job has environment', () =>
        setupAndMount({
          jobData: {
            deployment_status: {
              environment: {
                environment_path: '/path',
                name: 'foo',
              },
            },
          },
        }).then(() => {
          expect(findEnvironmentsBlockComponent().exists()).toBe(true);
        }));

      it('does not render environment block when job has environment', () =>
        setupAndMount().then(() => {
          expect(findEnvironmentsBlockComponent().exists()).toBe(false);
        }));
    });

    describe('erased block', () => {
      it('renders erased block when `erased` is true', () =>
        setupAndMount({
          jobData: {
            erased_by: {
              username: 'root',
              web_url: 'gitlab.com/root',
            },
            erased_at: '2016-11-07T11:11:16.525Z',
          },
        }).then(() => {
          expect(findErasedBlock().exists()).toBe(true);
        }));

      it('does not render erased block when `erased` is false', () =>
        setupAndMount({
          jobData: {
            erased_at: null,
          },
        }).then(() => {
          expect(findErasedBlock().exists()).toBe(false);
        }));
    });

    describe('empty states block', () => {
      it('renders empty state when job does not have trace and is not running', () =>
        setupAndMount({
          jobData: {
            has_trace: false,
            status: {
              group: 'pending',
              icon: 'status_pending',
              label: 'pending',
              text: 'pending',
              details_path: 'path',
              illustration: {
                image: 'path',
                size: '340',
                title: 'Empty State',
                content: 'This is an empty state',
              },
              action: {
                button_title: 'Retry job',
                method: 'post',
                path: '/path',
              },
            },
          },
        }).then(() => {
          expect(findEmptyState().exists()).toBe(true);
        }));

      it('does not render empty state when job does not have trace but it is running', () =>
        setupAndMount({
          jobData: {
            has_trace: false,
            status: {
              group: 'running',
              icon: 'status_running',
              label: 'running',
              text: 'running',
              details_path: 'path',
            },
          },
        }).then(() => {
          expect(findEmptyState().exists()).toBe(false);
        }));

      it('does not render empty state when job has trace but it is not running', () =>
        setupAndMount({ jobData: { has_trace: true } }).then(() => {
          expect(findEmptyState().exists()).toBe(false);
        }));

      it('displays remaining time for a delayed job', () => {
        const oneHourInMilliseconds = 3600000;
        jest
          .spyOn(Date, 'now')
          .mockImplementation(
            () => new Date(delayedJobFixture.scheduled_at).getTime() - oneHourInMilliseconds,
          );
        return setupAndMount({ jobData: delayedJobFixture }).then(() => {
          expect(findEmptyState().exists()).toBe(true);

          const title = findJobEmptyStateTitle().text();

          expect(title).toEqual('This is a delayed job to run in 01:00:00');
        });
      });
    });

    describe('sidebar', () => {
      it('has no blank blocks', (done) => {
        setupAndMount({
          jobData: {
            duration: null,
            finished_at: null,
            erased_at: null,
            queued: null,
            runner: null,
            coverage: null,
            tags: [],
            cancel_path: null,
          },
        })
          .then(() => {
            const blocks = wrapper.findAll('.blocks-container > *').wrappers;
            expect(blocks.length).toBeGreaterThan(0);

            blocks.forEach((block) => {
              expect(block.text().trim()).not.toBe('');
            });
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('archived job', () => {
    beforeEach(() => setupAndMount({ jobData: { archived: true } }));

    it('renders warning about job being archived', () => {
      expect(findArchivedJob().exists()).toBe(true);
    });
  });

  describe('non-archived job', () => {
    beforeEach(() => setupAndMount());

    it('does not warning about job being archived', () => {
      expect(findArchivedJob().exists()).toBe(false);
    });
  });

  describe('trace controls', () => {
    beforeEach(() =>
      setupAndMount({
        traceData: {
          html: '<span>Update</span>',
          status: 'success',
          append: false,
          size: 50,
          total: 100,
          complete: true,
        },
      }),
    );

    it('should render scroll buttons', () => {
      expect(findJobTraceScrollTop().exists()).toBe(true);
      expect(findJobTraceScrollBottom().exists()).toBe(true);
    });

    it('should render link to raw ouput', () => {
      expect(findJobTraceController().exists()).toBe(true);
    });

    it('should render link to erase job', () => {
      expect(findJobTraceEraseLink().exists()).toBe(true);
    });
  });
});
