import { shallowMount } from '@vue/test-utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import UrlSyncComponent from '~/vue_shared/components/url_sync.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  mergeUrlParams: jest.fn((query, url) => `urlParams: ${query} ${url}`),
}));

jest.mock('~/lib/utils/common_utils', () => ({
  historyPushState: jest.fn(),
}));

describe('url sync component', () => {
  let wrapper;
  const mockQuery = { group_id: '5014437163714', project_ids: ['5014437608314'] };
  const TEST_HOST = 'http://testhost/';

  setWindowLocation(TEST_HOST);

  const findButton = () => wrapper.find('button');

  const createComponent = ({ query = mockQuery, scopedSlots, slots } = {}) => {
    wrapper = shallowMount(UrlSyncComponent, {
      propsData: { query },
      scopedSlots,
      slots,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const expectUrlSync = (query, times, mergeUrlParamsReturnValue) => {
    expect(mergeUrlParams).toHaveBeenCalledTimes(times);
    expect(mergeUrlParams).toHaveBeenCalledWith(query, TEST_HOST, { spreadArrays: true });

    expect(historyPushState).toHaveBeenCalledTimes(times);
    expect(historyPushState).toHaveBeenCalledWith(mergeUrlParamsReturnValue);
  };

  describe('with query as a props', () => {
    it('immediately syncs the query to the URL', () => {
      createComponent();

      expectUrlSync(mockQuery, 1, mergeUrlParams.mock.results[0].value);
    });

    describe('when the query is modified', () => {
      const newQuery = { foo: true };

      it('updates the URL with the new query', async () => {
        createComponent();
        // using setProps to test the watcher
        await wrapper.setProps({ query: newQuery });

        expectUrlSync(mockQuery, 2, mergeUrlParams.mock.results[1].value);
      });
    });
  });

  describe('with scoped slot', () => {
    const scopedSlots = {
      default: `
        <button @click="props.updateQuery({bar: 'baz'})">Update Query </button>
        `,
    };

    it('renders the scoped slot', () => {
      createComponent({ query: null, scopedSlots });

      expect(findButton().exists()).toBe(true);
    });

    it('syncs the url with the scoped slots function', () => {
      createComponent({ query: null, scopedSlots });

      findButton().trigger('click');

      expectUrlSync({ bar: 'baz' }, 1, mergeUrlParams.mock.results[0].value);
    });
  });

  describe('with slot', () => {
    const slots = {
      default: '<button>Normal Slot</button>',
    };

    it('renders the default slot', () => {
      createComponent({ query: null, slots });

      expect(findButton().exists()).toBe(true);
    });
  });
});
