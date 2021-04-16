import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import DetailRow from '~/jobs/components/sidebar_detail_row.vue';
import SidebarJobDetailsContainer from '~/jobs/components/sidebar_job_details_container.vue';
import createStore from '~/jobs/store';
import job from '../mock_data';

describe('Job Sidebar Details Container', () => {
  let store;
  let wrapper;

  const findJobTimeout = () => wrapper.findByTestId('job-timeout');
  const findJobTags = () => wrapper.findByTestId('job-tags');
  const findAllDetailsRow = () => wrapper.findAll(DetailRow);

  const createWrapper = ({ props = {} } = {}) => {
    store = createStore();
    wrapper = extendedWrapper(
      shallowMount(SidebarJobDetailsContainer, {
        propsData: props,
        store,
        stubs: {
          DetailRow,
        },
      }),
    );
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('when no details are available', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render an empty container', () => {
      expect(wrapper.html()).toBe('');
    });

    it.each(['duration', 'erased_at', 'finished_at', 'queued', 'runner', 'coverage'])(
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
      ['duration', 'Duration: 6 seconds'],
      ['erased_at', 'Erased: 3 weeks ago'],
      ['finished_at', 'Finished: 3 weeks ago'],
      ['queued', 'Queued: 9 seconds'],
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

  describe('when all the info are available', () => {
    it('renders all the details components', async () => {
      createWrapper();
      await store.dispatch('receiveJobSuccess', job);

      expect(findAllDetailsRow()).toHaveLength(7);
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

      expect(wrapper.html()).toBe('');
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
