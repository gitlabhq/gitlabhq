import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlAlert, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { cacheConfig } from '~/ci/catalog/graphql/settings';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';

import getCiCatalogResourceSharedData from '~/ci/catalog/graphql/queries/get_ci_catalog_resource_shared_data.query.graphql';

import CiResourceDetails from '~/ci/catalog/components/details/ci_resource_details.vue';
import CiResourceDetailsPage from '~/ci/catalog/components/pages/ci_resource_details_page.vue';
import CiResourceHeader from '~/ci/catalog/components/details/ci_resource_header.vue';
import CiResourceHeaderSkeletonLoader from '~/ci/catalog/components/details/ci_resource_header_skeleton_loader.vue';

import { createRouter } from '~/ci/catalog/router/index';
import { CI_RESOURCE_DETAILS_PAGE_NAME } from '~/ci/catalog/router/constants';
import { catalogSharedDataMock } from '../../mock';

Vue.use(VueApollo);
Vue.use(VueRouter);

const defaultSharedData = { ...catalogSharedDataMock.data.ciCatalogResource };
const baseRoute = '/';
const resourcesPageComponentStub = {
  name: 'page-component',
  template: '<div>Hello</div>',
};

describe('CiResourceDetailsPage', () => {
  let wrapper;
  let sharedDataResponse;
  let router;

  const defaultProps = {};

  const defaultProvide = {
    ciCatalogPath: '/ci/catalog/resources',
  };

  const findDetailsComponent = () => wrapper.findComponent(CiResourceDetails);
  const findHeaderComponent = () => wrapper.findComponent(CiResourceHeader);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findVisibilityAlert = () => wrapper.findComponent(GlAlert);
  const findHeaderSkeletonLoader = () => wrapper.findComponent(CiResourceHeaderSkeletonLoader);

  const createComponent = ({ props = {} } = {}) => {
    const handlers = [[getCiCatalogResourceSharedData, sharedDataResponse]];

    const mockApollo = createMockApollo(handlers, undefined, cacheConfig);

    wrapper = shallowMount(CiResourceDetailsPage, {
      router,
      apolloProvider: mockApollo,
      provide: {
        ...defaultProvide,
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(async () => {
    sharedDataResponse = jest.fn();

    router = createRouter(baseRoute, resourcesPageComponentStub);

    await router.push({
      name: CI_RESOURCE_DETAILS_PAGE_NAME,
      params: { id: defaultSharedData.webPath },
    });
  });

  describe('when the app is loading', () => {
    describe('and shared data is pre-fetched', () => {
      beforeEach(() => {
        // By mocking a return value and not a promise, we skip the loading
        // to simulate having the pre-fetched query
        sharedDataResponse.mockReturnValueOnce(catalogSharedDataMock);
        createComponent();
      });

      it('renders the header skeleton loader', () => {
        expect(findHeaderSkeletonLoader().exists()).toBe(false);
      });

      it('passes down the loading state to the header component', () => {
        sharedDataResponse.mockReturnValueOnce(catalogSharedDataMock);

        expect(findHeaderComponent().props()).toMatchObject({
          isLoadingData: false,
        });
      });
    });

    describe('and shared data is not pre-fetched', () => {
      beforeEach(() => {
        sharedDataResponse.mockResolvedValue(catalogSharedDataMock);
        createComponent();
      });

      it('does not render the header skeleton', () => {
        expect(findHeaderSkeletonLoader().exists()).toBe(false);
      });

      it('passes all loading state to the header component as true', () => {
        expect(findHeaderComponent().props()).toMatchObject({
          isLoadingData: true,
        });
      });
    });
  });

  describe('and there are no resources', () => {
    beforeEach(async () => {
      const mockError = new Error('error');
      sharedDataResponse.mockRejectedValue(mockError);

      createComponent();
      await waitForPromises();
    });

    it('renders the empty state', () => {
      expect(findDetailsComponent().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('primaryButtonLink')).toBe(defaultProvide.ciCatalogPath);
    });
  });

  describe('when data has loaded', () => {
    beforeEach(async () => {
      sharedDataResponse.mockResolvedValue(catalogSharedDataMock);
      createComponent();

      await waitForPromises();
    });

    it('does not render the header skeleton loader', () => {
      expect(findHeaderSkeletonLoader().exists()).toBe(false);
    });

    describe('Catalog header', () => {
      it('exists', () => {
        expect(findHeaderComponent().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findHeaderComponent().props()).toMatchObject({
          isLoadingData: false,
          resource: defaultSharedData,
        });
      });
    });

    describe('Catalog details', () => {
      it('exists', () => {
        expect(findDetailsComponent().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findDetailsComponent().props()).toEqual({
          resourcePath: cleanLeadingSeparator(defaultSharedData.webPath),
          version: defaultSharedData.versions.nodes[0].name,
        });
      });
    });
  });

  describe('Project visibility', () => {
    it('does not render alert for public projects', async () => {
      sharedDataResponse.mockResolvedValue(catalogSharedDataMock);
      createComponent();
      await waitForPromises();

      expect(findVisibilityAlert().exists()).toBe(false);
    });

    it('renders alert for private projects', async () => {
      const privateProjectMockData = {
        data: {
          ciCatalogResource: {
            ...catalogSharedDataMock.data.ciCatalogResource,
            ...{ visibilityLevel: 'private' },
          },
        },
      };
      sharedDataResponse.mockResolvedValue(privateProjectMockData);
      createComponent();
      await waitForPromises();

      expect(findVisibilityAlert().exists()).toBe(true);
    });
  });
});
