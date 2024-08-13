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
import { MOCK_QUERY, mockGetBlobSearchQuery } from '../../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);

describe('GlobalSearchResultsApp', () => {
  let wrapper;
  let apolloMock;

  const getterSpies = {
    currentScope: jest.fn(() => 'blobs'),
  };

  const blobSearchHandler = jest.fn().mockResolvedValue(mockGetBlobSearchQuery);

  const createComponent = (initialState = {}) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
      },
      getters: getterSpies,
    });
    apolloMock = createMockApollo([[getBlobSearchQuery, blobSearchHandler]]);
    wrapper = shallowMountExtended(GlobalSearchResultsApp, {
      apolloProvider: apolloMock,
      store,
    });
  };

  afterEach(() => {
    apolloMock = null;
  });

  const findZoektBlobResults = () => wrapper.findComponent(ZoektBlobResults);

  describe('component', () => {
    describe.each`
      scope       | searchType    | isRendered
      ${'blobs'}  | ${'zoekt'}    | ${true}
      ${'issues'} | ${'zoekt'}    | ${false}
      ${'blobs'}  | ${'advanced'} | ${false}
      ${'issues'} | ${'basic'}    | ${false}
    `('template', ({ scope, searchType, isRendered }) => {
      beforeEach(async () => {
        getterSpies.currentScope = jest.fn(() => scope);
        createComponent({ query: { scope }, searchType });
        jest.advanceTimersByTime(500);
        await waitForPromises();
      });

      it(`renders component based on conditions`, () => {
        expect(findZoektBlobResults().exists()).toBe(isRendered);
      });
    });
  });
});
