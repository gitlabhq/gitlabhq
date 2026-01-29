import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { historyPushState, historyReplaceState } from '~/lib/utils/common_utils';
import { mergeUrlParams, setUrlParams } from '~/lib/utils/url_utility';
import UrlSyncComponent, {
  URL_SET_PARAMS_STRATEGY,
  HISTORY_REPLACE_UPDATE_METHOD,
} from '~/vue_shared/components/url_sync.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  mergeUrlParams: jest.fn((query, url) => `urlParams: ${JSON.stringify(query)} ${url}`),
  setUrlParams: jest.fn((query, { url }) => `urlParams: ${JSON.stringify(query)} ${url}`),
  queryToObject: jest.fn(() => ({})),
}));

jest.mock('~/lib/utils/common_utils', () => ({
  historyPushState: jest.fn(),
  historyReplaceState: jest.fn(),
}));

describe('url sync component', () => {
  let wrapper;
  const mockQuery = { group_id: '5014437163714', project_ids: ['5014437608314'] };

  const findButton = () => wrapper.find('button');

  const createMockRouter = () => ({
    push: jest.fn().mockResolvedValue(),
    replace: jest.fn().mockResolvedValue(),
  });

  const createComponent = ({
    props = {},
    scopedSlots,
    slots,
    mockRouter = null,
    mockRoute = null,
  } = {}) => {
    wrapper = shallowMount(UrlSyncComponent, {
      propsData: {
        query: mockQuery,
        ...props,
      },
      scopedSlots,
      slots,
      mocks: mockRouter ? { $router: mockRouter, $route: mockRoute || { query: {} } } : undefined,
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
    expect(setUrlParams).toHaveBeenCalledWith(query, {
      url: window.location.href,
      clearParams: true,
      railsArraySyntax: true,
      decodeParams: true,
    });

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

  describe('with useRouter prop', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    describe('popstate behavior', () => {
      it('does not add popstate listener when useRouter is true', () => {
        const removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');
        const mockRouter = createMockRouter();
        createComponent({
          props: { query: null, useRouter: true },
          mockRouter,
        });
        wrapper.destroy();

        const popstateCall = removeEventListenerSpy.mock.calls.find(
          ([event]) => event === 'popstate',
        );
        expect(popstateCall).toBeUndefined();
      });

      it('emits popstate when $route.query changes', () => {
        const mockRouter = createMockRouter();
        createComponent({
          props: { query: null, useRouter: true },
          mockRouter,
          mockRoute: { query: {} },
        });

        UrlSyncComponent.watch['$route.query'].handler.call(wrapper.vm, { new: 'query' }, {});

        expect(wrapper.emitted('popstate')).toHaveLength(1);
        expect(wrapper.emitted('popstate')[0][0]).toEqual({
          state: { query: { new: 'query' } },
        });
      });
    });

    describe('router navigation', () => {
      const scopedSlots = {
        default: `<button @click="props.updateQuery({foo: 'bar'})">Update</button>`,
      };
      let mockRouter;

      beforeEach(() => {
        mockRouter = createMockRouter();
        createComponent({
          props: { query: null, useRouter: true },
          scopedSlots,
          mockRouter,
        });
      });

      it('uses router.push when updating query', () => {
        findButton().trigger('click');

        expect(mockRouter.push).toHaveBeenCalledWith({ query: { foo: 'bar' } });
        expect(historyPushState).not.toHaveBeenCalled();
      });

      it('uses router.replace when historyUpdateMethod is replace', async () => {
        await wrapper.setProps({ historyUpdateMethod: HISTORY_REPLACE_UPDATE_METHOD });

        findButton().trigger('click');

        expect(mockRouter.replace).toHaveBeenCalledWith({ query: { foo: 'bar' } });
        expect(historyReplaceState).not.toHaveBeenCalled();
      });

      it('removes null and undefined values from query', () => {
        mockRouter = createMockRouter();
        createComponent({
          props: { query: null, useRouter: true },
          scopedSlots: {
            default: `<button @click="props.updateQuery({keep: 'value', removeNull: null})">Update</button>`,
          },
          mockRouter,
        });

        findButton().trigger('click');

        expect(mockRouter.push).toHaveBeenCalledWith({
          query: { keep: 'value' },
        });
      });

      it('handles NavigationDuplicated error gracefully', async () => {
        const navigationError = new Error('Navigation duplicated');
        navigationError.name = 'NavigationDuplicated';
        mockRouter.push.mockRejectedValue(navigationError);

        findButton().trigger('click');

        await nextTick();

        expect(mockRouter.push).toHaveBeenCalled();
      });
    });

    describe('query merging strategies', () => {
      it('merges query params when using merge strategy', () => {
        const mockRouter = createMockRouter();
        createComponent({
          props: { query: null, useRouter: true },
          scopedSlots: {
            default: `<button @click="props.updateQuery({new: 'param'})">Update</button>`,
          },
          mockRouter,
          mockRoute: { query: { existing: 'param' } },
        });

        findButton().trigger('click');

        expect(mockRouter.push).toHaveBeenCalledWith({
          query: { existing: 'param', new: 'param' },
        });
      });

      it('replaces query params when using set strategy', () => {
        const mockRouter = createMockRouter();
        createComponent({
          props: { query: null, useRouter: true, urlParamsUpdateStrategy: URL_SET_PARAMS_STRATEGY },
          scopedSlots: {
            default: `<button @click="props.updateQuery({new: 'param'})">Update</button>`,
          },
          mockRouter,
          mockRoute: { query: { existing: 'param' } },
        });

        findButton().trigger('click');

        expect(mockRouter.push).toHaveBeenCalledWith({
          query: { new: 'param' },
        });
      });

      it('does not navigate when query has not changed', () => {
        const mockRouter = createMockRouter();
        createComponent({
          props: { query: null, useRouter: true },
          scopedSlots: {
            default: `<button @click="props.updateQuery({same: 'query'})">Update</button>`,
          },
          mockRouter,
          mockRoute: { query: { same: 'query' } },
        });

        findButton().trigger('click');

        expect(mockRouter.push).not.toHaveBeenCalled();
      });

      it('converts array values to use bracket notation', () => {
        const mockRouter = createMockRouter();
        createComponent({
          props: { query: null, useRouter: true },
          scopedSlots: {
            default: `<button @click="props.updateQuery({search: ['term1', 'term2'], orderBy: 'UPDATED'})">Update</button>`,
          },
          mockRouter,
        });

        findButton().trigger('click');

        expect(mockRouter.push).toHaveBeenCalledWith({
          query: { 'search[]': ['term1', 'term2'], orderBy: 'UPDATED' },
        });
      });

      it('normalizes bracket notation keys from currentQuery when merging', () => {
        const mockRouter = createMockRouter();
        createComponent({
          props: { query: null, useRouter: true },
          scopedSlots: {
            default: `<button @click="props.updateQuery({search: ['newTerm']})">Update</button>`,
          },
          mockRouter,
          mockRoute: { query: { 'search[]': ['oldTerm'], orderBy: 'UPDATED' } },
        });

        findButton().trigger('click');

        expect(mockRouter.push).toHaveBeenCalledWith({
          query: { 'search[]': ['newTerm'], orderBy: 'UPDATED' },
        });
      });
    });
  });
});
