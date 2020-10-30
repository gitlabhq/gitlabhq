import { shallowMount } from '@vue/test-utils';
import Sidebar from '~/jobs/components/sidebar.vue';
import StagesDropdown from '~/jobs/components/stages_dropdown.vue';
import JobsContainer from '~/jobs/components/jobs_container.vue';
import createStore from '~/jobs/store';
import job, { jobsInStage } from '../mock_data';
import { extendedWrapper } from '../../helpers/vue_test_utils_helper';

describe('Sidebar details block', () => {
  let store;
  let wrapper;

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

      expect(wrapper.find('.js-retry-button').exists()).toBe(false);
    });
  });

  describe('without terminal path', () => {
    it('does not render terminal link', async () => {
      createWrapper();
      await store.dispatch('receiveJobSuccess', job);

      expect(wrapper.find('.js-terminal-link').exists()).toBe(false);
    });
  });

  describe('with terminal path', () => {
    it('renders terminal link', async () => {
      createWrapper();
      await store.dispatch('receiveJobSuccess', { ...job, terminal_path: 'job/43123/terminal' });

      expect(wrapper.find('.js-terminal-link').exists()).toBe(true);
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createWrapper();
      return store.dispatch('receiveJobSuccess', job);
    });

    it('should render link to new issue', () => {
      expect(wrapper.findByTestId('job-new-issue').attributes('href')).toBe(job.new_issue_path);
      expect(wrapper.find('[data-testid="job-new-issue"]').text()).toBe('New issue');
    });

    it('should render link to retry job', () => {
      expect(wrapper.find('.js-retry-button').attributes('href')).toBe(job.retry_path);
    });

    it('should render link to cancel job', () => {
      expect(wrapper.find('.js-cancel-job').attributes('href')).toBe(job.cancel_path);
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

      it('does not render job container', () => {
        expect(wrapper.find('.js-jobs-container').exists()).toBe(false);
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
