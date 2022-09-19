import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ArtifactsBlock from '~/jobs/components/job/sidebar/artifacts_block.vue';
import JobRetryForwardDeploymentModal from '~/jobs/components/job/sidebar/job_retry_forward_deployment_modal.vue';
import JobsContainer from '~/jobs/components/job/sidebar/jobs_container.vue';
import Sidebar from '~/jobs/components/job/sidebar/sidebar.vue';
import StagesDropdown from '~/jobs/components/job/sidebar/stages_dropdown.vue';
import createStore from '~/jobs/store';
import job, { jobsInStage } from '../../mock_data';

describe('Sidebar details block', () => {
  let store;
  let wrapper;

  const forwardDeploymentFailure = 'forward_deployment_failure';
  const findModal = () => wrapper.findComponent(JobRetryForwardDeploymentModal);
  const findArtifactsBlock = () => wrapper.findComponent(ArtifactsBlock);
  const findNewIssueButton = () => wrapper.findByTestId('job-new-issue');
  const findTerminalLink = () => wrapper.findByTestId('terminal-link');

  const createWrapper = (props) => {
    store = createStore();

    store.state.job = job;

    wrapper = extendedWrapper(
      shallowMount(Sidebar, {
        propsData: {
          ...props,
        },

        store,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('without terminal path', () => {
    it('does not render terminal link', async () => {
      createWrapper();
      await store.dispatch('receiveJobSuccess', job);

      expect(findTerminalLink().exists()).toBe(false);
    });
  });

  describe('with terminal path', () => {
    it('renders terminal link', async () => {
      createWrapper();
      await store.dispatch('receiveJobSuccess', { ...job, terminal_path: 'job/43123/terminal' });

      expect(findTerminalLink().exists()).toBe(true);
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createWrapper();
      return store.dispatch('receiveJobSuccess', job);
    });

    it('should render link to new issue', () => {
      expect(findNewIssueButton().attributes('href')).toBe(job.new_issue_path);
      expect(findNewIssueButton().text()).toBe('New issue');
    });
  });

  describe('forward deployment failure', () => {
    describe('when the relevant data is missing', () => {
      it.each`
        retryPath         | failureReason
        ${null}           | ${null}
        ${''}             | ${''}
        ${job.retry_path} | ${''}
        ${''}             | ${forwardDeploymentFailure}
        ${job.retry_path} | ${'unmet_prerequisites'}
      `(
        'should not render the modal when path and failure are $retryPath, $failureReason',
        async ({ retryPath, failureReason }) => {
          createWrapper();
          await store.dispatch('receiveJobSuccess', {
            ...job,
            failure_reason: failureReason,
            retry_path: retryPath,
          });
          expect(findModal().exists()).toBe(false);
        },
      );
    });

    describe('when there is the relevant error', () => {
      beforeEach(() => {
        createWrapper();
        return store.dispatch('receiveJobSuccess', {
          ...job,
          failure_reason: forwardDeploymentFailure,
        });
      });

      it('should render the modal', () => {
        expect(findModal().exists()).toBe(true);
      });
    });
  });

  describe('stages dropdown', () => {
    beforeEach(() => {
      createWrapper();
      return store.dispatch('receiveJobSuccess', { ...job, stage: 'aStage' });
    });

    describe('with stages', () => {
      it('renders value provided as selectedStage as selected', () => {
        expect(wrapper.findComponent(StagesDropdown).props('selectedStage')).toBe('aStage');
      });
    });

    describe('without jobs for stages', () => {
      beforeEach(() => store.dispatch('receiveJobSuccess', job));

      it('does not render jobs container', () => {
        expect(wrapper.findComponent(JobsContainer).exists()).toBe(false);
      });
    });

    describe('with jobs for stages', () => {
      beforeEach(async () => {
        await store.dispatch('receiveJobSuccess', job);
        await store.dispatch('receiveJobsForStageSuccess', jobsInStage.latest_statuses);
      });

      it('renders list of jobs', () => {
        expect(wrapper.findComponent(JobsContainer).exists()).toBe(true);
      });
    });
  });

  describe('artifacts', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('artifacts are not shown if there are no properties other than locked', () => {
      expect(findArtifactsBlock().exists()).toBe(false);
    });

    it('artifacts are shown if present', async () => {
      store.state.job.artifact = {
        download_path: '/root/ci-project/-/jobs/1960/artifacts/download',
        browse_path: '/root/ci-project/-/jobs/1960/artifacts/browse',
        keep_path: '/root/ci-project/-/jobs/1960/artifacts/keep',
        expire_at: '2021-03-23T17:57:11.211Z',
        expired: false,
        locked: false,
      };

      await nextTick();

      expect(findArtifactsBlock().exists()).toBe(true);
    });
  });
});
