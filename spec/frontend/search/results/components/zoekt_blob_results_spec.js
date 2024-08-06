import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlCard } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import getBlobSearchQuery from '~/search/graphql/blob_search_zoekt.query.graphql';
import ZoektBlobResults from '~/search/results/components/zoekt_blob_results.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

import EmptyResult from '~/search/results/components/result_empty.vue';
import { MOCK_QUERY, mockGetBlobSearchQuery } from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);
Vue.use(Vuex);

describe('ZoektBlobResults', () => {
  let wrapper;

  const getterSpies = {
    currentScope: jest.fn(() => 'blobs'),
  };

  const blobSearchHandler = jest.fn().mockResolvedValue(mockGetBlobSearchQuery);
  const mockQueryLoading = jest.fn().mockReturnValue(new Promise(() => {}));
  const mockQueryEmpty = jest.fn().mockReturnValue({});
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
    });
    // apolloMock = createMockApollo([[getBlobSearchQuery, blobSearchHandler]]);
    wrapper = shallowMountExtended(ZoektBlobResults, {
      apolloProvider,
      store,
      stubs: {
        GlCard,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyResult = () => wrapper.findComponent(EmptyResult);

  describe('when loading results', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: mockQueryLoading,
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
      createComponent();
      jest.advanceTimersByTime(500);
      await waitForPromises();
    });

    it(`renders component properly`, async () => {
      await nextTick();
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when component has no results', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: mockQueryEmpty,
      });
      jest.advanceTimersByTime(500);
      await waitForPromises();
    });

    it(`renders component properly`, async () => {
      await nextTick();
      expect(findEmptyResult().exists()).toBe(true);
    });
  });

  describe('when component has load error', () => {
    beforeEach(async () => {
      createComponent({ queryHandler: mockQueryError });
      jest.runOnlyPendingTimers();
      await nextTick();
    });

    it('calls createAlert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Could not load search results. Please refresh the page to try again.',
        captureError: true,
        error: expect.any(Error),
      });
    });
  });
});
