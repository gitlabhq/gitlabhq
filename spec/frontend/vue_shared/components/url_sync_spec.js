import { shallowMount } from '@vue/test-utils';
import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams, setUrlParams } from '~/lib/utils/url_utility';
import UrlSyncComponent, { URL_SET_PARAMS_STRATEGY } from '~/vue_shared/components/url_sync.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  mergeUrlParams: jest.fn((query, url) => `urlParams: ${JSON.stringify(query)} ${url}`),
  setUrlParams: jest.fn((query, url) => `urlParams: ${JSON.stringify(query)} ${url}`),
}));

jest.mock('~/lib/utils/common_utils', () => ({
  historyPushState: jest.fn(),
}));

describe('url sync component', () => {
  let wrapper;
  const mockQuery = { group_id: '5014437163714', project_ids: ['5014437608314'] };

  const findButton = () => wrapper.find('button');

  const createComponent = ({
    query = mockQuery,
    scopedSlots,
    slots,
    urlParamsUpdateStrategy,
  } = {}) => {
    wrapper = shallowMount(UrlSyncComponent, {
      propsData: { query, ...(urlParamsUpdateStrategy && { urlParamsUpdateStrategy }) },
      scopedSlots,
      slots,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const expectUrlSyncWithMergeUrlParams = (query, times, mergeUrlParamsReturnValue) => {
    expect(mergeUrlParams).toHaveBeenCalledTimes(times);
    expect(mergeUrlParams).toHaveBeenCalledWith(query, window.location.href, {
      spreadArrays: true,
    });

    expect(historyPushState).toHaveBeenCalledTimes(times);
    expect(historyPushState).toHaveBeenCalledWith(mergeUrlParamsReturnValue);
  };

  const expectUrlSyncWithSetUrlParams = (query, times, setUrlParamsReturnValue) => {
    expect(setUrlParams).toHaveBeenCalledTimes(times);
    expect(setUrlParams).toHaveBeenCalledWith(query, window.location.href, true, true, true);

    expect(historyPushState).toHaveBeenCalledTimes(times);
    expect(historyPushState).toHaveBeenCalledWith(setUrlParamsReturnValue);
  };

  describe('with query as a props', () => {
    it('immediately syncs the query to the URL', () => {
      createComponent();

      expectUrlSyncWithMergeUrlParams(mockQuery, 1, mergeUrlParams.mock.results[0].value);
    });

    describe('when the query is modified', () => {
      const newQuery = { foo: true };

      it('updates the URL with the new query', async () => {
        createComponent();
        // using setProps to test the watcher
        await wrapper.setProps({ query: newQuery });

        expectUrlSyncWithMergeUrlParams(mockQuery, 2, mergeUrlParams.mock.results[1].value);
      });
    });
  });

  describe('with url-params-update-strategy equals to URL_SET_PARAMS_STRATEGY', () => {
    it('uses setUrlParams to generate URL', () => {
      createComponent({
        urlParamsUpdateStrategy: URL_SET_PARAMS_STRATEGY,
      });

      expectUrlSyncWithSetUrlParams(mockQuery, 1, setUrlParams.mock.results[0].value);
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

      expectUrlSyncWithMergeUrlParams({ bar: 'baz' }, 1, mergeUrlParams.mock.results[0].value);
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
