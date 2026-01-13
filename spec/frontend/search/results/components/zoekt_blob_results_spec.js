import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlLoadingIcon, GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ZoektBlobResults from '~/search/results/components/zoekt_blob_results.vue';
import waitForPromises from 'helpers/wait_for_promises';
import * as scrollUtils from '~/lib/utils/scroll_utils';
import * as panels from '~/lib/utils/panels';

import { MOCK_QUERY, mockGetBlobSearchQuery } from '../../mock_data';

jest.mock('~/alert');

Vue.use(Vuex);

describe('ZoektBlobResults', () => {
  let wrapper;

  const getterSpies = {
    currentScope: jest.fn(() => 'blobs'),
  };

  const defaultState = { ...MOCK_QUERY, query: { scope: 'blobs' }, searchType: 'zoekt' };
  const defaultProps = { hasResults: true, isLoading: false, blobSearch: {} };

  const createComponent = ({ initialState = {}, propsData = {} } = {}) => {
    const store = new Vuex.Store({
      state: {
        ...defaultState,
        ...initialState,
      },
      getters: getterSpies,
    });
    wrapper = shallowMountExtended(ZoektBlobResults, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      store,
      stubs: {
        GlCard,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(() => {
    // Fake timers are needed for the debounced scroll handler in the component
    jest.useFakeTimers({ legacyFakeTimers: true });
    window.gon.user_color_mode = 'gl-light';
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  describe('when loading results', () => {
    beforeEach(async () => {
      createComponent({
        propsData: { isLoading: true },
      });
      jest.advanceTimersByTime(500);
      await waitForPromises();
    });

    it('renders loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when component loads normally', () => {
    beforeEach(async () => {
      createComponent({
        propsData: {
          blobSearch: mockGetBlobSearchQuery.data.blobSearch,
        },
      });
      jest.advanceTimersByTime(500);
      await waitForPromises();
    });

    it(`renders component properly`, async () => {
      await nextTick();
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('scroll position preservation', () => {
    let mockScrollingElement;
    let scrollHandler;
    let scrollToSpy;

    beforeEach(() => {
      mockScrollingElement = {
        scrollTop: 500,
        addEventListener: jest.fn((event, handler) => {
          if (event === 'scroll') {
            scrollHandler = handler;
          }
        }),
        removeEventListener: jest.fn(),
      };
      jest.spyOn(panels, 'getScrollingElement').mockReturnValue(mockScrollingElement);
      scrollToSpy = jest.spyOn(scrollUtils, 'scrollTo').mockImplementation(() => {});
    });

    afterEach(() => {
      window.history.replaceState({}, document.title);
    });

    it('saves scroll position to history state on scroll', () => {
      createComponent({
        propsData: {
          blobSearch: mockGetBlobSearchQuery.data.blobSearch,
        },
      });

      scrollHandler();
      jest.advanceTimersByTime(100);

      expect(window.history.state).toEqual(expect.objectContaining({ scrollPosition: 500 }));
    });

    it('restores scroll position from history state when loading completes', async () => {
      window.history.replaceState({ scrollPosition: 300 }, document.title);

      createComponent({
        propsData: {
          blobSearch: mockGetBlobSearchQuery.data.blobSearch,
          isLoading: false,
        },
      });

      await nextTick();

      expect(scrollToSpy).toHaveBeenCalledWith(
        { top: 300, behavior: 'auto' },
        mockScrollingElement,
      );
    });
  });
});
