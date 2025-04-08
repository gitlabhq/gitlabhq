import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getBlobSearchQuery from '~/search/graphql/blob_search_zoekt.query.graphql';
import GlobalSearchResultsApp from '~/search/results/components/app.vue';
import ZoektBlobResults from '~/search/results/components/zoekt_blob_results.vue';
import StatusBar from '~/search/results/components/status_bar.vue';
import EmptyResult from '~/search/results/components/result_empty.vue';
import ErrorResult from '~/search/results/components/result_error.vue';
import mutations from '~/search/store/mutations';
import {
  MOCK_QUERY,
  mockGetBlobSearchQuery,
  mockGetBlobSearchQueryEmpty,
  MOCK_NAVIGATION_DATA,
} from '../../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);

jest.mock('~/alert');

describe('GlobalSearchResultsApp', () => {
  let wrapper;

  const getterSpies = {
    currentScope: jest.fn(() => 'blobs'),
  };

  const blobSearchHandler = jest.fn().mockResolvedValue(mockGetBlobSearchQuery);
  const mockQueryLoading = jest.fn().mockReturnValue(new Promise(() => {}));
  const mockQueryEmpty = jest.fn().mockReturnValue(mockGetBlobSearchQueryEmpty);
  const mockQueryError = jest.fn().mockRejectedValue(new Error('Network error'));

  const createComponent = ({
    initialState = { query: { scope: 'blobs' }, searchType: 'zoekt' },
    queryHandler = blobSearchHandler,
  } = {}) => {
    const requestHandlers = [[getBlobSearchQuery, queryHandler]];
    const apolloProvider = createMockApollo(requestHandlers);

    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      getters: getterSpies,
      mutations,
    });

    wrapper = shallowMountExtended(GlobalSearchResultsApp, {
      apolloProvider,
      store,
    });
  };

  const findZoektBlobResults = () => wrapper.findComponent(ZoektBlobResults);
  const findEmptyResult = () => wrapper.findComponent(EmptyResult);
  const findStatusBar = () => wrapper.findComponent(StatusBar);
  const findError = () => wrapper.findComponent(ErrorResult);

  describe('when loading results', () => {
    beforeEach(async () => {
      createComponent({
        initialState: { query: { scope: 'blobs' }, searchType: 'zoekt' },
        queryHandler: mockQueryLoading,
      });
      jest.advanceTimersByTime(500);
      await waitForPromises();
    });

    it('renders loading icon', () => {
      expect(findZoektBlobResults().props('isLoading')).toBe(true);
    });
  });

  describe('when component has load error', () => {
    beforeEach(async () => {
      createComponent({
        initialState: { query: { scope: 'blobs' }, searchType: 'zoekt' },
        queryHandler: mockQueryError,
      });
      jest.runOnlyPendingTimers();
      await waitForPromises();
    });

    it('renders alert', () => {
      expect(findError().exists()).toBe(true);
      expect(findZoektBlobResults().exists()).toBe(false);
    });
  });

  describe('when component has no results', () => {
    beforeEach(async () => {
      createComponent({
        initialState: {
          query: { scope: 'blobs' },
          searchType: 'zoekt',
          navigation: MOCK_NAVIGATION_DATA,
        },
        queryHandler: mockQueryEmpty,
      });
      jest.runOnlyPendingTimers();
      await waitForPromises();
    });

    it(`Renders empty state`, async () => {
      await waitForPromises();
      expect(findZoektBlobResults().exists()).toBe(false);
      expect(findEmptyResult().exists()).toBe(true);
    });

    it('Renders status bar in correct order', () => {
      expect(findStatusBar().exists()).toBe(true);
      expect(findStatusBar().element.nextElementSibling).toBe(findEmptyResult().element);
    });
  });

  describe('when we have results', () => {
    let spy;
    beforeEach(async () => {
      getterSpies.currentScope = jest.fn(() => 'blobs');
      createComponent({
        initialState: {
          query: { scope: 'blobs' },
          searchType: 'zoekt',
          navigation: MOCK_NAVIGATION_DATA,
        },
        queryHandler: blobSearchHandler,
      });
      spy = jest.spyOn(wrapper?.vm?.$store, 'commit');
      jest.advanceTimersByTime(500);
      await waitForPromises();
    });

    it(`calls mutation RECEIVE_NAVIGATION_COUNT`, () => {
      expect(spy).toHaveBeenCalledWith('RECEIVE_NAVIGATION_COUNT', {
        count: '369',
        key: 'blobs',
      });
    });

    it(`correctly renders results`, () => {
      expect(findZoektBlobResults().exists()).toBe(true);
    });

    it(`correctly renders status`, () => {
      expect(findStatusBar().exists()).toBe(true);
    });
  });
});
