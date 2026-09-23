import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createMockSubscription } from 'mock-apollo-client';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';
import BaseLayout from '~/vue_shared/components/base_layout.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import EmptyState from '~/ci/job_details/components/empty_state.vue';
import JobRunForm from '~/ci/job_details/components/job_run_form.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import EnvironmentsBlock from '~/ci/job_details/components/environments_block.vue';
import ErasedBlock from '~/ci/job_details/components/erased_block.vue';
import JobApp from '~/ci/job_details/job_app.vue';
import getJobQuery from '~/ci/job_details/graphql/queries/get_job.query.graphql';
import jobCiStatusUpdatedSubscription from '~/ci/job_details/graphql/subscriptions/job_ci_status_updated.subscription.graphql';
import JobLog from '~/ci/job_details/components/log/log.vue';
import JobLogTopBar from '~/ci/job_details/components/job_log_top_bar.vue';
import Sidebar from '~/ci/job_details/components/sidebar/sidebar.vue';
import SidebarHeader from '~/ci/job_details/components/sidebar/sidebar_header.vue';
import StuckBlock from '~/ci/job_details/components/stuck_block.vue';
import UnmetPrerequisitesBlock from '~/ci/job_details/components/unmet_prerequisites_block.vue';
import createStore from '~/ci/job_details/store';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { MANUAL_STATUS } from '~/ci/constants';
import job from 'jest/ci/jobs_mock_data';
import { mockPendingJobData, mockJobResponse } from './mock_data';

jest.mock('~/panel_breakpoint_instance');

Vue.use(VueApollo);

describe('Job App', () => {
  Vue.use(Vuex);

  let store;
  let wrapper;
  let mock;
  let triggerResize;
  let jobQueryHandler;
  let subscriptionHandler;
  let mockSubscription;

  const initSettings = {
    jobEndpoint: '/group1/project1/-/jobs/99.json',
    logEndpoint: '/group1/project1/-/jobs/99/trace',
    testReportSummaryUrl: '/group1/project1/-/jobs/99/test_report_summary.json',
  };

  const props = {
    artifactHelpUrl: 'help/artifact',
    deploymentHelpUrl: 'help/deployment',
    runnerSettingsUrl: 'settings/ci-cd/runners',
    terminalPath: 'jobs/123/terminal',
    projectPath: 'user-name/project-name',
  };

  const createComponent = ({
    abilities = {},
    stubs = {},
    jobQueryResponse = mockJobResponse,
    ...options
  } = {}) => {
    jobQueryHandler = jest.fn().mockResolvedValue(jobQueryResponse);
    mockSubscription = createMockSubscription();
    subscriptionHandler = jest.fn().mockReturnValue(mockSubscription);
    const apolloProvider = createMockApollo([[getJobQuery, jobQueryHandler]]);
    apolloProvider.defaultClient.setRequestHandler(
      jobCiStatusUpdatedSubscription,
      subscriptionHandler,
    );

    wrapper = shallowMountExtended(JobApp, {
      propsData: { ...props },
      store,
      apolloProvider,
      provide: {
        glAbilities: { troubleshootJobWithAi: false, ...abilities },
        projectPath: 'user-name/project-name',
      },
      stubs: {
        DetailLayout,
        BaseLayout,
        PageHeading,
        PanelActionsPortal: { template: '<div><slot></slot></div>' },
        ...stubs,
      },
      ...options,
    });
  };

  const setupAndMount = async ({
    jobData = {},
    jobLogData = {},
    abilities = {},
    ...options
  } = {}) => {
    mock.onGet(initSettings.jobEndpoint).replyOnce(HTTP_STATUS_OK, { ...job, ...jobData });
    mock.onGet(initSettings.logEndpoint).reply(HTTP_STATUS_OK, jobLogData);

    const asyncInit = store.dispatch('init', initSettings);

    createComponent({ abilities, ...options });

    await asyncInit;
    jest.runOnlyPendingTimers();
    await axios.waitForAll();
    await nextTick();
  };

  const findLoadingComponent = () => wrapper.findComponent(GlLoadingIcon);
  const findSidebar = () => wrapper.findComponent(Sidebar);
  const findSidebarHeader = () => wrapper.findComponent(SidebarHeader);
  const findStuckBlockComponent = () => wrapper.findComponent(StuckBlock);
  const findFailedJobComponent = () => wrapper.findComponent(UnmetPrerequisitesBlock);
  const findEnvironmentsBlockComponent = () => wrapper.findComponent(EnvironmentsBlock);
  const findErasedBlock = () => wrapper.findComponent(ErasedBlock);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findJobForm = () => wrapper.findComponent(JobRunForm);
  const findJobLog = () => wrapper.findComponent(JobLog);
  const findJobLogTopBar = () => wrapper.findComponent(JobLogTopBar);
  const findJobName = () => wrapper.findByTestId('job-name');
  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findNewIssueButton = () => wrapper.findByTestId('job-new-issue');

  const findDetailLayout = () => wrapper.findComponent(DetailLayout);
  const findArchivedJob = () => wrapper.findByTestId('archived-job');
  const findStickyFooter = () => wrapper.findByTestId('rca-bar-component');

  beforeEach(() => {
    PanelBreakpointInstance.addResizeListener.mockImplementation((callback) => {
      triggerResize = callback;
    });
    // Default to desktop so the sidebar stays open (rendered) after mount.
    PanelBreakpointInstance.isDesktop.mockReturnValue(true);
    mock = new MockAdapter(axios);
    store = createStore();
  });

  afterEach(() => {
    mock.restore();
    // eslint-disable-next-line @gitlab/vtu-no-explicit-wrapper-destroy
    wrapper.destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      store.state.isLoading = true;
      createComponent();
    });

    it('renders the layout in a loading state without the job log', () => {
      expect(findLoadingComponent().exists()).toBe(true);
      expect(findDetailLayout().props('loading')).toBe(true);
      expect(findJobLog().exists()).toBe(false);
    });
  });

  describe('when resizing', () => {
    beforeEach(async () => {
      await setupAndMount();

      jest.spyOn(store, 'dispatch');
    });

    it('shows sidebar', async () => {
      jest.spyOn(PanelBreakpointInstance, 'isDesktop').mockReturnValue(true);
      expect(store.dispatch).not.toHaveBeenCalledWith('showSidebar');

      store.state.isSidebarOpen = false;
      triggerResize();
      await waitForPromises();

      expect(store.dispatch).toHaveBeenCalledWith('showSidebar');
    });

    it('hides sidebar on mobile', () => {
      expect(store.dispatch).not.toHaveBeenCalledWith('hideSidebar');

      jest.spyOn(PanelBreakpointInstance, 'isDesktop').mockReturnValue(false);

      store.state.isSidebarOpen = true;
      triggerResize();

      expect(store.dispatch).toHaveBeenCalledWith('hideSidebar');
    });
  });

  describe('while scrolling inside a content panel', () => {
    let contentPanelWrapper;

    beforeEach(async () => {
      setHTMLFixture('<div class="js-static-panel-inner"></div>');
      contentPanelWrapper = document.querySelector('.js-static-panel-inner');

      await setupAndMount({
        directives: {
          GlResizeObserver: createMockDirective('gl-resize-observer'),
        },
        attachTo: document.body,
      });

      jest.spyOn(store, 'dispatch');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('should update scrolling when content panel is scrolled', async () => {
      expect(store.dispatch).not.toHaveBeenCalledWith('toggleScrollButtons');

      contentPanelWrapper.dispatchEvent(new Event('scroll'));
      await waitForPromises();

      expect(store.dispatch).toHaveBeenCalledWith('toggleScrollButtons');
    });

    it('should update scrolling when resized', async () => {
      expect(store.dispatch).not.toHaveBeenCalledWith('toggleScrollButtons');

      getBinding(wrapper.element, 'gl-resize-observer').value();
      await waitForPromises();

      expect(store.dispatch).toHaveBeenCalledWith('toggleScrollButtons');
    });
  });

  describe('with successful request', () => {
    describe('Header section', () => {
      const findGlAlert = () => wrapper.findComponent(GlAlert);
      describe('job callout message', () => {
        it('should not render the reason when reason is absent', () =>
          setupAndMount().then(() => {
            expect(findGlAlert().exists()).toBe(false);
          }));

        it('should render the reason when reason is present', () =>
          setupAndMount({
            jobData: {
              callout_message: 'There is an unkown failure, please try again',
            },
          }).then(() => {
            expect(findGlAlert().exists()).toBe(true);
            expect(findGlAlert().text()).toBe('There is an unkown failure, please try again');
          }));
      });

      describe('attestation warning message', () => {
        it('should not render the warning when the warning is absent', async () => {
          await setupAndMount();
          expect(findGlAlert().exists()).toBe(false);
        });

        it('should render the warning when the warning is present', async () => {
          await setupAndMount({
            jobData: {
              supply_chain_attestation_status: 'error',
            },
          });
          expect(findGlAlert().exists()).toBe(true);
          expect(findGlAlert().text()).toBe(
            'An error occurred while generating an attestation for build artifacts in this job. Please check the configuration, and try again.',
          );
        });
      });

      it('queries the job header data and renders the job name', async () => {
        await setupAndMount();
        await waitForPromises();

        expect(jobQueryHandler).toHaveBeenCalledWith({
          fullPath: 'user-name/project-name',
          id: `gid://gitlab/Ci::Build/${job.id}`,
        });
        expect(findJobName().text()).toContain(mockJobResponse.data.project.job.name);
      });

      it('renders the job name inside the page heading (h1)', async () => {
        await setupAndMount();
        await waitForPromises();

        const heading = wrapper.findByTestId('page-heading');

        expect(heading.element.tagName).toBe('H1');
        expect(heading.find('[data-testid="job-name"]').exists()).toBe(true);
      });

      it('does not render the job name when the header query returns no job', async () => {
        const emptyResponse = {
          data: { project: { ...mockJobResponse.data.project, job: null } },
        };

        await setupAndMount({ jobQueryResponse: emptyResponse });
        await waitForPromises();

        expect(findJobName().exists()).toBe(false);
      });

      it('renders the new issue button in the panel header actions', async () => {
        await setupAndMount({ jobData: { new_issue_path: 'new/issue/path' } });
        await waitForPromises();

        expect(findNewIssueButton().attributes('href')).toBe('new/issue/path');
      });

      it('does not render the new issue button without a new issue path', async () => {
        await setupAndMount({ jobData: { new_issue_path: null } });
        await waitForPromises();

        expect(findNewIssueButton().exists()).toBe(false);
      });
    });

    describe('real time updates', () => {
      it('updates the job status from the subscription', async () => {
        await setupAndMount();
        await waitForPromises();

        expect(findCiIcon().props('status')).toMatchObject({ text: 'Passed' });

        mockSubscription.next({
          data: {
            ciJobStatusUpdated: {
              id: 'gid://gitlab/Ci::Build/389',
              detailedStatus: {
                __typename: 'DetailedStatus',
                detailsPath: '/root/ci-project/-/jobs/389',
                icon: 'status_running',
                id: 'running-389-389',
                text: 'Running',
              },
            },
          },
        });

        await waitForPromises();

        expect(subscriptionHandler).toHaveBeenCalledWith({
          jobId: `gid://gitlab/Ci::Build/${job.id}`,
        });
        expect(findCiIcon().props('status')).toMatchObject({ text: 'Running' });
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
          }));
      });

      it('does not render stuck block when there are runners', () =>
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
              action: {
                confirmation_message: null,
                button_title: 'Retry job',
                method: 'post',
                path: '/path',
              },
              illustration: {
                content: 'Run this job again in order to create the necessary resources.',
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

    describe('sticky footer', () => {
      it('does not display the sticky footer if troubleshootJobWithAi is false', () =>
        setupAndMount({
          jobData: {
            status: {
              group: 'failed',
              icon: 'status_failed',
            },
            has_trace: true,
            runners: {
              available: true,
            },
            tags: [],
          },
        }).then(() => {
          expect(findStickyFooter().exists()).toBe(false);
        }));

      it('displays the sticky footer if troubleshootJobWithAi is true', () =>
        setupAndMount({
          jobData: {
            status: {
              group: 'failed',
              icon: 'status_failed',
            },
            has_trace: true,
            runners: {
              available: true,
            },
            tags: [],
          },
          abilities: {
            troubleshootJobWithAi: true,
          },
        }).then(() => {
          expect(findStickyFooter().exists()).toBe(true);
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

    describe('job form block', () => {
      it('renders job form block when job is playable and not scheduled', async () => {
        await setupAndMount({
          jobData: {
            has_trace: false,
            playable: true,
            scheduled: false,
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
                confirmation_message: 'Confirm',
                button_title: 'Retry job',
                method: 'post',
                path: '/path',
              },
            },
          },
        });
        expect(findJobForm().props()).toMatchObject({
          isRetryable: true,
          jobId: job.id,
          jobName: job.name,
          confirmationMessage: 'Confirm',
        });
      });

      it('renders job form block when the sidebar header emits update variables', async () => {
        await setupAndMount({
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
        });
        findSidebarHeader().vm.$emit('update-variables');
        await nextTick();
        expect(findJobForm().exists()).toBe(true);
      });

      it('does not render job form block when job has log but it is not running', async () => {
        await setupAndMount({ jobData: { has_trace: true } });
        expect(findJobForm().exists()).toBe(false);
      });
    });

    describe('empty states block', () => {
      it('renders empty state when job does not have log and is not running', () =>
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

      it('does not render empty state when job does not have log but it is running', () =>
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

      it('does not render empty state when job has log but it is not running', () =>
        setupAndMount({ jobData: { has_trace: true } }).then(() => {
          expect(findEmptyState().exists()).toBe(false);
        }));
    });

    describe('sidebar', () => {
      it('renders sidebar', async () => {
        await setupAndMount();

        expect(findSidebar().exists()).toBe(true);
      });

      it('renders sidebar for job retrial', async () => {
        await setupAndMount();
        findSidebar().vm.$emit('update-variables');
        await nextTick();

        expect(findSidebar().exists()).toBe(true);
      });
    });
  });

  describe('archived job', () => {
    beforeEach(() => setupAndMount({ jobData: { archived: true } }));

    it('renders notice about job being archived', () => {
      expect(findArchivedJob().exists()).toBe(true);
    });
  });

  describe('non-archived job', () => {
    beforeEach(() => setupAndMount());

    it('does not render notice about job being archived', () => {
      expect(findArchivedJob().exists()).toBe(false);
    });
  });

  describe('job log', () => {
    beforeEach(async () => {
      await setupAndMount();
      jest.spyOn(store, 'dispatch');
    });

    it('should render job log header', () => {
      expect(findJobLogTopBar().exists()).toBe(true);
    });

    it('should render job log', () => {
      expect(findJobLog().exists()).toBe(true);

      expect(findJobLog().props()).toEqual({ searchResults: [] });
    });
  });

  describe('job log polling', () => {
    beforeEach(() => {
      jest.spyOn(store, 'dispatch');
    });

    it('should poll job log by default', async () => {
      await setupAndMount({
        jobData: mockPendingJobData,
      });

      expect(store.dispatch).toHaveBeenCalledWith('fetchJobLog');
    });

    it('should NOT poll job log for manual variables form empty state', async () => {
      const manualPendingJobData = mockPendingJobData;
      manualPendingJobData.status.group = MANUAL_STATUS;

      await setupAndMount({
        jobData: manualPendingJobData,
      });

      expect(store.dispatch).not.toHaveBeenCalledWith('fetchJobLog');
    });
  });
});
