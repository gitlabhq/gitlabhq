import { shallowMount } from '@vue/test-utils';
import Sidebar, { forwardDeploymentFailureModalId } from '~/jobs/components/sidebar.vue';
import StagesDropdown from '~/jobs/components/stages_dropdown.vue';
import JobsContainer from '~/jobs/components/jobs_container.vue';
import JobRetryForwardDeploymentModal from '~/jobs/components/job_retry_forward_deployment_modal.vue';
import JobRetryButton from '~/jobs/components/job_sidebar_retry_button.vue';
import createStore from '~/jobs/store';
import job, { jobsInStage } from '../mock_data';
import { extendedWrapper } from '../../helpers/vue_test_utils_helper';

describe('Sidebar details block', () => {
  let store;
  let wrapper;

  const forwardDeploymentFailure = 'forward_deployment_failure';
  const findModal = () => wrapper.find(JobRetryForwardDeploymentModal);
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findNewIssueButton = () => wrapper.findByTestId('job-new-issue');
  const findRetryButton = () => wrapper.find(JobRetryButton);
  const findTerminalLink = () => wrapper.findByTestId('terminal-link');

  const createWrapper = ({ props = {} } = {}) => {
    store = createStore();
    wrapper = extendedWrapper(
      shallowMount(Sidebar, {
        ...props,
        store,
      }),
    );
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('when there is no retry path retry', () => {
    it('should not render a retry button', async () => {
      createWrapper();
      const copy = { ...job, retry_path: null };
      await store.dispatch('receiveJobSuccess', copy);

      expect(findRetryButton().exists()).toBe(false);
    });
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

    it('should render the retry button', () => {
      expect(findRetryButton().props('href')).toBe(job.retry_path);
    });

    it('should render link to cancel job', () => {
      expect(findCancelButton().text()).toMatch('Cancel');
      expect(findCancelButton().attributes('href')).toBe(job.cancel_path);
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

      it('should provide the modal id to the button and modal', () => {
        expect(findRetryButton().props('modalId')).toBe(forwardDeploymentFailureModalId);
        expect(findModal().props('modalId')).toBe(forwardDeploymentFailureModalId);
      });

      it('should provide the retry path to the button and modal', () => {
        expect(findRetryButton().props('href')).toBe(job.retry_path);
        expect(findModal().props('href')).toBe(job.retry_path);
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
        expect(wrapper.find(StagesDropdown).props('selectedStage')).toBe('aStage');
      });
    });

    describe('without jobs for stages', () => {
      beforeEach(() => store.dispatch('receiveJobSuccess', job));

      it('does not render jobs container', () => {
        expect(wrapper.find(JobsContainer).exists()).toBe(false);
      });
    });

    describe('with jobs for stages', () => {
      beforeEach(async () => {
        await store.dispatch('receiveJobSuccess', job);
        await store.dispatch('receiveJobsForStageSuccess', jobsInStage.latest_statuses);
      });

      it('renders list of jobs', () => {
        expect(wrapper.find(JobsContainer).exists()).toBe(true);
      });
    });
  });
});
