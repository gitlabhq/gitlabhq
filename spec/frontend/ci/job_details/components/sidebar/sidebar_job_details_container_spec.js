import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import DetailRow from '~/ci/job_details/components/sidebar/sidebar_detail_row.vue';
import SidebarJobDetailsContainer from '~/ci/job_details/components/sidebar/sidebar_job_details_container.vue';
import createStore from '~/ci/job_details/store';
import job, { testSummaryData, testSummaryDataWithFailures } from 'jest/ci/jobs_mock_data';

describe('Job Sidebar Details Container', () => {
  let store;
  let wrapper;

  const findJobTimeout = () => wrapper.findByTestId('job-timeout');
  const findJobTags = () => wrapper.findByTestId('job-tags');
  const findAllDetailsRow = () => wrapper.findAllComponents(DetailRow);
  const findTestSummary = () => wrapper.findByTestId('test-summary');

  const createWrapper = ({ props = {} } = {}) => {
    store = createStore();
    wrapper = extendedWrapper(
      shallowMount(SidebarJobDetailsContainer, {
        propsData: props,
        store,
        stubs: {
          DetailRow,
        },
        provide: {
          pipelineTestReportUrl: '/root/test-unit-test-reports/-/pipelines/512/test_report',
        },
      }),
    );
  };

  describe('when no details are available', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render an empty container', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });

    it.each(['duration', 'erased_at', 'finished_at', 'queued_at', 'runner', 'coverage'])(
      'should not render %s details when missing',
      async (detail) => {
        await store.dispatch('receiveJobSuccess', { [detail]: undefined });

        expect(findAllDetailsRow()).toHaveLength(0);
      },
    );
  });

  describe('when some of the details are available', () => {
    beforeEach(createWrapper);

    it.each([
      ['duration', 'Elapsed time: 6 seconds'],
      ['erased_at', 'Erased: 3 weeks ago'],
      ['finished_at', 'Finished: 3 weeks ago'],
      ['queued_duration', 'Queued: 9 seconds'],
      ['runner', 'Runner: #1 (ABCDEFGH) local ci runner'],
      ['coverage', 'Coverage: 20%'],
    ])('uses %s to render job-%s', async (detail, value) => {
      await store.dispatch('receiveJobSuccess', { [detail]: job[detail] });
      const detailsRow = findAllDetailsRow();

      expect(detailsRow).toHaveLength(1);
      expect(detailsRow.at(0).text()).toBe(value);
    });

    it('only renders tags', async () => {
      const { tags } = job;
      await store.dispatch('receiveJobSuccess', { tags });
      const tagsComponent = findJobTags();

      expect(tagsComponent.text()).toBe('Tags: tag');
    });
  });

  describe('when code coverage exists but is zero', () => {
    it('renders the coverage value', async () => {
      createWrapper();

      await store.dispatch('receiveJobSuccess', {
        ...job,
        coverage: 0,
      });

      expect(findAllDetailsRow().at(6).text()).toBe('Coverage: 0%');
    });
  });

  describe('when all the info are available', () => {
    it('renders all the details components', async () => {
      createWrapper();
      await store.dispatch('receiveJobSuccess', job);

      expect(findAllDetailsRow()).toHaveLength(7);
    });

    describe('duration row', () => {
      it('renders all the details components', async () => {
        createWrapper();
        await store.dispatch('receiveJobSuccess', job);

        expect(findAllDetailsRow().at(0).text()).toBe('Duration: 6 seconds');
      });
    });
  });

  describe('Test summary details', () => {
    it('displays the test summary section', async () => {
      createWrapper();

      await store.dispatch('receiveJobSuccess', job);
      await store.dispatch('receiveTestSummarySuccess', testSummaryData);

      expect(findTestSummary().exists()).toBe(true);
      expect(findTestSummary().text()).toContain('Test summary');
      expect(findTestSummary().text()).toContain('1');
    });

    it('does not display the test summary section', async () => {
      createWrapper();

      await store.dispatch('receiveJobSuccess', job);

      expect(findTestSummary().exists()).toBe(false);
    });

    it('displays the failure count message', async () => {
      createWrapper();

      await store.dispatch('receiveJobSuccess', job);
      await store.dispatch('receiveTestSummarySuccess', testSummaryDataWithFailures);

      expect(findTestSummary().text()).toContain('Test summary');
      expect(findTestSummary().text()).toContain('1 of 2 failed');
    });
  });

  describe('timeout', () => {
    const {
      metadata: { timeout_human_readable, timeout_source },
    } = job;

    beforeEach(createWrapper);

    it('does not render if metadata is empty', async () => {
      const metadata = {};
      await store.dispatch('receiveJobSuccess', { metadata });
      const detailsRow = findAllDetailsRow();

      expect(wrapper.find('*').exists()).toBe(false);
      expect(detailsRow.exists()).toBe(false);
    });

    it('uses metadata to render timeout', async () => {
      const metadata = { timeout_human_readable };
      await store.dispatch('receiveJobSuccess', { metadata });
      const detailsRow = findAllDetailsRow();

      expect(detailsRow).toHaveLength(1);
      expect(detailsRow.at(0).text()).toBe('Timeout: 1m 40s');
    });

    it('uses metadata to render timeout and the source', async () => {
      const metadata = { timeout_human_readable, timeout_source };
      await store.dispatch('receiveJobSuccess', { metadata });
      const detailsRow = findAllDetailsRow();

      expect(detailsRow.at(0).text()).toBe('Timeout: 1m 40s (from runner)');
    });

    it('should not render when no time is provided', async () => {
      const metadata = { timeout_source };
      await store.dispatch('receiveJobSuccess', { metadata });

      expect(findJobTimeout().exists()).toBe(false);
    });
  });
});
