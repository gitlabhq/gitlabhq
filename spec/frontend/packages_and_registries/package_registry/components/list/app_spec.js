import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';

import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PackageListApp from '~/packages_and_registries/package_registry/components/list/app.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/list/package_title.vue';
import PackageSearch from '~/packages_and_registries/package_registry/components/list/package_search.vue';

import {
  PROJECT_RESOURCE_TYPE,
  GROUP_RESOURCE_TYPE,
  LIST_QUERY_DEBOUNCE_TIME,
} from '~/packages_and_registries/package_registry/constants';

import getPackagesQuery from '~/packages_and_registries/package_registry/graphql/queries/get_packages.query.graphql';

import { packagesListQuery } from '../../mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/flash');

const localVue = createLocalVue();

describe('PackagesListApp', () => {
  let wrapper;
  let apolloProvider;

  const defaultProvide = {
    packageHelpUrl: 'packageHelpUrl',
    emptyListIllustration: 'emptyListIllustration',
    emptyListHelpUrl: 'emptyListHelpUrl',
    isGroupPage: true,
    fullPath: 'gitlab-org',
  };

  const PackageList = {
    name: 'package-list',
    template: '<div><slot name="empty-state"></slot></div>',
  };
  const GlLoadingIcon = { name: 'gl-loading-icon', template: '<div>loading</div>' };

  const findPackageTitle = () => wrapper.findComponent(PackageTitle);
  const findSearch = () => wrapper.findComponent(PackageSearch);

  const mountComponent = ({
    resolver = jest.fn().mockResolvedValue(packagesListQuery()),
    provide = defaultProvide,
  } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [[getPackagesQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(PackageListApp, {
      localVue,
      apolloProvider,
      provide,
      stubs: {
        GlEmptyState,
        GlLoadingIcon,
        PackageList,
        GlSprintf,
        GlLink,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const waitForDebouncedApollo = () => {
    jest.advanceTimersByTime(LIST_QUERY_DEBOUNCE_TIME);
    return waitForPromises();
  };

  it('renders', async () => {
    mountComponent();

    await waitForDebouncedApollo();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('has a package title', async () => {
    mountComponent();

    await waitForDebouncedApollo();

    expect(findPackageTitle().exists()).toBe(true);
    expect(findPackageTitle().props('count')).toBe(2);
  });

  describe('search component', () => {
    it('exists', () => {
      mountComponent();

      expect(findSearch().exists()).toBe(true);
    });

    it('on update triggers a new query with updated values', async () => {
      const resolver = jest.fn().mockResolvedValue(packagesListQuery());
      mountComponent({ resolver });

      const payload = {
        sort: 'VERSION_DESC',
        filters: { packageName: 'foo', packageType: 'CONAN' },
      };

      findSearch().vm.$emit('update', payload);

      await waitForDebouncedApollo();
      jest.advanceTimersByTime(LIST_QUERY_DEBOUNCE_TIME);

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({
          groupSort: payload.sort,
          ...payload.filters,
        }),
      );
    });
  });

  describe.each`
    type                     | sortType
    ${PROJECT_RESOURCE_TYPE} | ${'sort'}
    ${GROUP_RESOURCE_TYPE}   | ${'groupSort'}
  `('$type query', ({ type, sortType }) => {
    let provide;
    let resolver;

    const isGroupPage = type === GROUP_RESOURCE_TYPE;

    beforeEach(() => {
      provide = { ...defaultProvide, isGroupPage };
      resolver = jest.fn().mockResolvedValue(packagesListQuery(type));
      mountComponent({ provide, resolver });
      return waitForDebouncedApollo();
    });

    it('succeeds', () => {
      expect(findPackageTitle().props('count')).toBe(2);
    });

    it('calls the resolver with the right parameters', () => {
      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ isGroupPage, [sortType]: '' }),
      );
    });
  });
});
