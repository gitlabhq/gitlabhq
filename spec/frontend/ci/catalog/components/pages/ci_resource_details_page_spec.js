import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { cacheConfig } from '~/ci/catalog/graphql/settings';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';

import getCiCatalogResourceSharedData from '~/ci/catalog/graphql/queries/get_ci_catalog_resource_shared_data.query.graphql';
import getCiCatalogResourceVersions from '~/ci/catalog/graphql/queries/get_ci_catalog_resource_versions.query.graphql';

import CiResourceDetails from '~/ci/catalog/components/details/ci_resource_details.vue';
import CiResourceDetailsPage from '~/ci/catalog/components/pages/ci_resource_details_page.vue';
import CiResourceHeader from '~/ci/catalog/components/details/ci_resource_header.vue';
import CiResourceHeaderSkeletonLoader from '~/ci/catalog/components/details/ci_resource_header_skeleton_loader.vue';

import { createRouter } from '~/ci/catalog/router/index';
import { CI_RESOURCE_DETAILS_PAGE_NAME } from '~/ci/catalog/router/constants';
import { catalogSharedDataMock, mockVersionsResponse } from '../../mock';

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
  let versionsResponse;
  let router;

  const defaultProps = {};

  const defaultProvide = {
    ciCatalogPath: '/ci/catalog/resources',
  };

  const findDetailsComponent = () => wrapper.findComponent(CiResourceDetails);
  const findHeaderComponent = () => wrapper.findComponent(CiResourceHeader);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findHeaderSkeletonLoader = () => wrapper.findComponent(CiResourceHeaderSkeletonLoader);

  const createComponent = ({ props = {} } = {}) => {
    const handlers = [
      [getCiCatalogResourceVersions, versionsResponse],
      [getCiCatalogResourceSharedData, sharedDataResponse],
    ];

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
    versionsResponse = jest.fn();

    router = createRouter(baseRoute, resourcesPageComponentStub);

    await router.push({
      name: CI_RESOURCE_DETAILS_PAGE_NAME,
      params: { id: defaultSharedData.webPath },
    });
  });

  describe('when the app is loading', () => {
    beforeEach(() => {
      versionsResponse.mockResolvedValue(mockVersionsResponse);
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
      versionsResponse.mockResolvedValue(mockVersionsResponse);
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
          versions: [
            {
              value: 'gid://gitlab/Ci::Catalog::Resources::Version/2',
              text: '1.1.0',
              createdAt: '2026-02-15',
            },
            {
              value: 'gid://gitlab/Ci::Catalog::Resources::Version/1',
              text: '1.0.0',
              createdAt: '2024-02-15',
            },
          ],
          initialVersionId: 'gid://gitlab/Ci::Catalog::Resources::Version/2',
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
          version: '1.1.0',
        });
      });
    });
  });

  describe('version selection', () => {
    beforeEach(async () => {
      versionsResponse.mockResolvedValue(mockVersionsResponse);
      sharedDataResponse.mockResolvedValue(catalogSharedDataMock);
      createComponent();
      await waitForPromises();
    });

    it('updates selectedVersion when header emits version-selected', async () => {
      await findHeaderComponent().vm.$emit('version-selected', '1.0.0');
      await waitForPromises();

      expect(findDetailsComponent().props('version')).toBe('1.0.0');
    });
  });

  describe('version from URL', () => {
    it('selects version from URL query parameter', async () => {
      await router.push({
        name: CI_RESOURCE_DETAILS_PAGE_NAME,
        params: { id: defaultSharedData.webPath },
        query: { version: '1.0.0' },
      });

      versionsResponse.mockResolvedValue(mockVersionsResponse);
      sharedDataResponse.mockResolvedValue(catalogSharedDataMock);
      createComponent();
      await waitForPromises();

      expect(findHeaderComponent().props('initialVersionId')).toBe(
        'gid://gitlab/Ci::Catalog::Resources::Version/1',
      );
      expect(findDetailsComponent().props('version')).toBe('1.0.0');
    });

    it('removes invalid version from URL and selects latest', async () => {
      const routerReplaceSpy = jest.spyOn(router, 'replace');

      await router.push({
        name: CI_RESOURCE_DETAILS_PAGE_NAME,
        params: { id: defaultSharedData.webPath },
        query: { version: 'invalid-version' },
      });

      versionsResponse.mockResolvedValue(mockVersionsResponse);
      sharedDataResponse.mockResolvedValue(catalogSharedDataMock);
      createComponent();
      await waitForPromises();

      expect(routerReplaceSpy).toHaveBeenCalledWith({ query: {} });
      expect(findHeaderComponent().props('initialVersionId')).toBe(
        'gid://gitlab/Ci::Catalog::Resources::Version/2',
      );
      expect(findDetailsComponent().props('version')).toBe('1.1.0');
    });
  });
});
