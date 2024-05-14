import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { createAlert } from '~/alert';

import CatalogHeader from '~/ci/catalog/components/list/catalog_header.vue';
import CiResourcesList from '~/ci/catalog/components/list/ci_resources_list.vue';
import CiResourcesPage from '~/ci/catalog/components/pages/ci_resources_page.vue';
import CatalogSearch from '~/ci/catalog/components/list/catalog_search.vue';
import CatalogTabs from '~/ci/catalog/components/list/catalog_tabs.vue';
import CatalogListSkeletonLoader from '~/ci/catalog/components/list/catalog_list_skeleton_loader.vue';
import EmptyState from '~/ci/catalog/components/list/empty_state.vue';

import { cacheConfig, resolvers } from '~/ci/catalog/graphql/settings';
import { DEFAULT_SORT_VALUE, SCOPE } from '~/ci/catalog/constants';
import typeDefs from '~/ci/catalog/graphql/typedefs.graphql';

import getCatalogResources from '~/ci/catalog/graphql/queries/get_ci_catalog_resources.query.graphql';
import getCatalogResourcesCount from '~/ci/catalog/graphql/queries/get_ci_catalog_resources_count.query.graphql';

import {
  emptyCatalogResponseBody,
  catalogResponseBody,
  catalogResourcesCountResponseBody,
} from '../../mock';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('CiResourcesPage', () => {
  let wrapper;
  let catalogResourcesResponse;
  let catalogResourcesCountResponse;

  const defaultQueryVariables = {
    first: 20,
    scope: SCOPE.all,
    searchTerm: null,
    sortValue: DEFAULT_SORT_VALUE,
  };

  const createComponent = () => {
    const handlers = [
      [getCatalogResources, catalogResourcesResponse],
      [getCatalogResourcesCount, catalogResourcesCountResponse],
    ];
    const mockApollo = createMockApollo(handlers, resolvers, { cacheConfig, typeDefs });

    wrapper = shallowMountExtended(CiResourcesPage, {
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const findCatalogHeader = () => wrapper.findComponent(CatalogHeader);
  const findCatalogSearch = () => wrapper.findComponent(CatalogSearch);
  const findCatalogTabs = () => wrapper.findComponent(CatalogTabs);
  const findCiResourcesList = () => wrapper.findComponent(CiResourcesList);
  const findLoadingState = () => wrapper.findComponent(CatalogListSkeletonLoader);
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  beforeEach(() => {
    catalogResourcesResponse = jest.fn();
    catalogResourcesCountResponse = jest.fn();
    catalogResourcesCountResponse.mockResolvedValue(catalogResourcesCountResponseBody);
  });

  describe('when initial queries are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a loading icon and no list', () => {
      expect(findLoadingState().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
      expect(findCiResourcesList().exists()).toBe(false);
    });
  });

  describe('when queries have loaded', () => {
    it('renders the Catalog Header', async () => {
      await createComponent();

      expect(findCatalogHeader().exists()).toBe(true);
    });

    describe('and there are no resources', () => {
      beforeEach(async () => {
        catalogResourcesResponse.mockResolvedValue(emptyCatalogResponseBody);

        await createComponent();
      });

      it('renders the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
      });

      it('renders the search', () => {
        expect(findCatalogSearch().exists()).toBe(true);
      });

      it('renders the tabs', () => {
        expect(findCatalogTabs().exists()).toBe(true);
      });

      it('does not render the list', () => {
        expect(findCiResourcesList().exists()).toBe(false);
      });
    });

    describe('and there are resources', () => {
      const { nodes, pageInfo } = catalogResponseBody.data.ciCatalogResources;

      beforeEach(async () => {
        catalogResourcesResponse.mockResolvedValue(catalogResponseBody);

        await createComponent();
      });

      it('renders the resources list', () => {
        expect(findLoadingState().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(false);
        expect(findCiResourcesList().exists()).toBe(true);
      });

      it('renders the catalog tabs', () => {
        expect(findCatalogTabs().exists()).toBe(true);
      });

      it('updates the scope after switching tabs', async () => {
        await findCatalogTabs().vm.$emit('setScope', SCOPE.namespaces);

        expect(catalogResourcesResponse).toHaveBeenCalledWith({
          ...defaultQueryVariables,
          scope: SCOPE.namespaces,
        });

        await findCatalogTabs().vm.$emit('setScope', SCOPE.all);

        expect(catalogResourcesResponse).toHaveBeenCalledWith({
          ...defaultQueryVariables,
          scope: SCOPE.all,
        });
      });

      it('passes down props to the resources list', () => {
        expect(findCiResourcesList().props()).toMatchObject({
          currentPage: 1,
          resources: nodes,
          pageInfo,
        });
      });

      it('renders the search and sort', () => {
        expect(findCatalogSearch().exists()).toBe(true);
      });
    });
  });

  describe('pagination', () => {
    it.each`
      eventName
      ${'onPrevPage'}
      ${'onNextPage'}
    `('refetch query with new params when receiving $eventName', async ({ eventName }) => {
      const { pageInfo } = catalogResponseBody.data.ciCatalogResources;

      catalogResourcesResponse.mockResolvedValue(catalogResponseBody);
      await createComponent();

      expect(catalogResourcesResponse).toHaveBeenCalledTimes(1);

      await findCiResourcesList().vm.$emit(eventName);

      expect(catalogResourcesResponse).toHaveBeenCalledTimes(2);

      if (eventName === 'onNextPage') {
        expect(catalogResourcesResponse.mock.calls[1][0]).toEqual({
          ...defaultQueryVariables,
          after: pageInfo.endCursor,
        });
      } else {
        expect(catalogResourcesResponse.mock.calls[1][0]).toEqual({
          ...defaultQueryVariables,
          before: pageInfo.startCursor,
          last: 20,
          first: null,
          scope: SCOPE.all,
        });
      }
    });
  });

  describe('search and sort', () => {
    describe('on initial load', () => {
      beforeEach(() => {
        catalogResourcesResponse.mockResolvedValue(catalogResponseBody);
      });

      it('calls the query without search or sort', async () => {
        await createComponent();

        expect(catalogResourcesResponse).toHaveBeenCalledTimes(1);
        expect(catalogResourcesResponse.mock.calls[0][0]).toEqual({
          ...defaultQueryVariables,
        });
      });

      it('calls the query with search when present in URL', async () => {
        setWindowLocation('?search=Hello');
        await createComponent();

        expect(catalogResourcesResponse).toHaveBeenCalledTimes(1);
        expect(catalogResourcesResponse.mock.calls[0][0]).toEqual({
          ...defaultQueryVariables,
          searchTerm: 'Hello',
        });
      });
    });

    describe('when sorting changes', () => {
      const newSort = 'MOST_AWESOME_ASC';

      beforeEach(async () => {
        catalogResourcesResponse.mockResolvedValue(catalogResponseBody);
        await createComponent();
        await findCatalogSearch().vm.$emit('update-sorting', newSort);
      });

      it('passes it to the graphql query', () => {
        expect(catalogResourcesResponse).toHaveBeenCalledTimes(2);
        expect(catalogResourcesResponse.mock.calls[1][0]).toEqual({
          ...defaultQueryVariables,
          sortValue: newSort,
        });
      });
    });

    describe('when search component emits a new search term', () => {
      const newSearch = 'sloths';

      describe('and there are no results', () => {
        beforeEach(async () => {
          catalogResourcesResponse.mockResolvedValue(emptyCatalogResponseBody);
          await createComponent();
        });

        it('renders the empty state and passes down the search query', async () => {
          await findCatalogSearch().vm.$emit('update-search-term', newSearch);
          await waitForPromises();

          expect(findEmptyState().exists()).toBe(true);
          expect(findEmptyState().props().searchTerm).toBe(newSearch);
        });
      });

      describe('and there are results', () => {
        beforeEach(async () => {
          catalogResourcesResponse.mockResolvedValue(catalogResponseBody);
          await createComponent();
          await findCatalogSearch().vm.$emit('update-search-term', newSearch);
        });

        it('passes it to the graphql query', () => {
          expect(catalogResourcesResponse).toHaveBeenCalledTimes(2);
          expect(catalogResourcesResponse.mock.calls[1][0]).toEqual({
            ...defaultQueryVariables,
            searchTerm: newSearch,
          });
        });
      });
    });
  });

  describe('pages count', () => {
    describe('when the fetchMore call succeeds', () => {
      beforeEach(async () => {
        catalogResourcesResponse.mockResolvedValue(catalogResponseBody);

        await createComponent();
      });

      it('increments and drecrements the page count correctly', async () => {
        expect(findCiResourcesList().props().currentPage).toBe(1);

        findCiResourcesList().vm.$emit('onNextPage');
        await waitForPromises();

        expect(findCiResourcesList().props().currentPage).toBe(2);

        await findCiResourcesList().vm.$emit('onPrevPage');
        await waitForPromises();

        expect(findCiResourcesList().props().currentPage).toBe(1);
      });
    });

    describe.each`
      event                   | payload
      ${'update-search-term'} | ${'cat'}
      ${'update-sorting'}     | ${'CREATED_ASC'}
    `('when $event event is emitted', ({ event, payload }) => {
      beforeEach(async () => {
        catalogResourcesResponse.mockResolvedValue(catalogResponseBody);
        await createComponent();
      });

      it('resets the page count', async () => {
        expect(findCiResourcesList().props().currentPage).toBe(1);

        findCiResourcesList().vm.$emit('onNextPage');
        await waitForPromises();

        expect(findCiResourcesList().props().currentPage).toBe(2);

        await findCatalogSearch().vm.$emit(event, payload);
        await waitForPromises();

        expect(findCiResourcesList().props().currentPage).toBe(1);
      });
    });

    describe('when the fetchMore call fails', () => {
      const errorMessage = 'there was an error';

      describe('for next page', () => {
        beforeEach(async () => {
          catalogResourcesResponse.mockResolvedValueOnce(catalogResponseBody);
          catalogResourcesResponse.mockRejectedValue({ message: errorMessage });

          await createComponent();
        });

        it('does not increment the page and calls createAlert', async () => {
          expect(findCiResourcesList().props().currentPage).toBe(1);

          findCiResourcesList().vm.$emit('onNextPage');
          await waitForPromises();

          expect(findCiResourcesList().props().currentPage).toBe(1);
          expect(createAlert).toHaveBeenCalledWith({ message: errorMessage, variant: 'danger' });
        });
      });

      describe('for previous page', () => {
        beforeEach(async () => {
          // Initial query
          catalogResourcesResponse.mockResolvedValueOnce(catalogResponseBody);
          // When clicking on next
          catalogResourcesResponse.mockResolvedValueOnce(catalogResponseBody);
          // when clicking on previous
          catalogResourcesResponse.mockRejectedValue({ message: errorMessage });

          await createComponent();
        });

        it('does not decrement the page and calls createAlert', async () => {
          expect(findCiResourcesList().props().currentPage).toBe(1);

          findCiResourcesList().vm.$emit('onNextPage');
          await waitForPromises();

          expect(findCiResourcesList().props().currentPage).toBe(2);

          findCiResourcesList().vm.$emit('onPrevPage');
          await waitForPromises();

          expect(findCiResourcesList().props().currentPage).toBe(2);
          expect(createAlert).toHaveBeenCalledWith({ message: errorMessage, variant: 'danger' });
        });
      });
    });
  });
});
