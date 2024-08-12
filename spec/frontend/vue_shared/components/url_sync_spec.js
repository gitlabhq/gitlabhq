import { shallowMount } from '@vue/test-utils';
import { historyPushState, historyReplaceState } from '~/lib/utils/common_utils';
import { mergeUrlParams, setUrlParams } from '~/lib/utils/url_utility';
import UrlSyncComponent, {
  URL_SET_PARAMS_STRATEGY,
  HISTORY_REPLACE_UPDATE_METHOD,
} from '~/vue_shared/components/url_sync.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  mergeUrlParams: jest.fn((query, url) => `urlParams: ${JSON.stringify(query)} ${url}`),
  setUrlParams: jest.fn((query, url) => `urlParams: ${JSON.stringify(query)} ${url}`),
}));

jest.mock('~/lib/utils/common_utils', () => ({
  historyPushState: jest.fn(),
  historyReplaceState: jest.fn(),
}));

describe('url sync component', () => {
  let wrapper;
  const mockQuery = { group_id: '5014437163714', project_ids: ['5014437608314'] };

  const findButton = () => wrapper.find('button');

  const createComponent = ({ props = {}, scopedSlots, slots } = {}) => {
    wrapper = shallowMount(UrlSyncComponent, {
      propsData: {
        query: mockQuery,
        ...props,
      },
      scopedSlots,
      slots,
    });
  };

  const expectUrlSyncWithMergeUrlParams = (
    query,
    times,
    mergeUrlParamsReturnValue,
    historyMethod = historyPushState,
    // eslint-disable-next-line max-params
  ) => {
    expect(mergeUrlParams).toHaveBeenCalledTimes(times);
    expect(mergeUrlParams).toHaveBeenCalledWith(query, window.location.href, {
      spreadArrays: true,
    });

    expect(historyMethod).toHaveBeenCalledTimes(times);
    expect(historyMethod).toHaveBeenCalledWith(mergeUrlParamsReturnValue);
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
        props: {
          urlParamsUpdateStrategy: URL_SET_PARAMS_STRATEGY,
        },
      });

      expectUrlSyncWithSetUrlParams(mockQuery, 1, setUrlParams.mock.results[0].value);
    });
  });

  describe('with history-update-method equals to HISTORY_REPLACE_UPDATE_METHOD', () => {
    it('uses historyReplaceState to update the URL', () => {
      createComponent({
        props: {
          historyUpdateMethod: HISTORY_REPLACE_UPDATE_METHOD,
        },
      });

      expectUrlSyncWithMergeUrlParams(
        mockQuery,
        1,
        mergeUrlParams.mock.results[0].value,
        historyReplaceState,
      );
    });
  });

  describe('with scoped slot', () => {
    const scopedSlots = {
      default: `
        <button @click="props.updateQuery({bar: 'baz'})">Update Query </button>
        `,
    };

    it('renders the scoped slot', () => {
      createComponent({ props: { query: null }, scopedSlots });

      expect(findButton().exists()).toBe(true);
    });

    it('syncs the url with the scoped slots function', () => {
      createComponent({ props: { query: null }, scopedSlots });

      findButton().trigger('click');

      expectUrlSyncWithMergeUrlParams({ bar: 'baz' }, 1, mergeUrlParams.mock.results[0].value);
    });
  });

  describe('with slot', () => {
    const slots = {
      default: '<button>Normal Slot</button>',
    };

    it('renders the default slot', () => {
      createComponent({ props: { query: null }, slots });

      expect(findButton().exists()).toBe(true);
    });
  });

  it('emits the popstate event when window dispatches popstate', () => {
    createComponent();

    window.dispatchEvent(new Event('popstate'));

    expect(wrapper.emitted('popstate')[0]).toHaveLength(1);
  });
});
