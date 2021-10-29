import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';

import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PackageListApp from '~/packages_and_registries/package_registry/components/list/app.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/list/package_title.vue';
import PackageSearch from '~/packages_and_registries/package_registry/components/list/package_search.vue';
import OriginalPackageList from '~/packages_and_registries/package_registry/components/list/packages_list.vue';
import DeletePackage from '~/packages_and_registries/package_registry/components/functional/delete_package.vue';

import {
  PROJECT_RESOURCE_TYPE,
  GROUP_RESOURCE_TYPE,
  LIST_QUERY_DEBOUNCE_TIME,
  GRAPHQL_PAGE_SIZE,
} from '~/packages_and_registries/package_registry/constants';

import getPackagesQuery from '~/packages_and_registries/package_registry/graphql/queries/get_packages.query.graphql';

import { packagesListQuery, packageData, pagination } from '../../mock_data';

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
    props: OriginalPackageList.props,
  };
  const GlLoadingIcon = { name: 'gl-loading-icon', template: '<div>loading</div>' };

  const searchPayload = {
    sort: 'VERSION_DESC',
    filters: { packageName: 'foo', packageType: 'CONAN' },
  };

  const findPackageTitle = () => wrapper.findComponent(PackageTitle);
  const findSearch = () => wrapper.findComponent(PackageSearch);
  const findListComponent = () => wrapper.findComponent(PackageList);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findDeletePackage = () => wrapper.findComponent(DeletePackage);

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
        GlSprintf,
        GlLink,
        PackageList,
        DeletePackage,
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

      findSearch().vm.$emit('update', searchPayload);

      await waitForDebouncedApollo();
      jest.advanceTimersByTime(LIST_QUERY_DEBOUNCE_TIME);

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({
          groupSort: searchPayload.sort,
          ...searchPayload.filters,
        }),
      );
    });
  });

  describe('list component', () => {
    let resolver;

    beforeEach(() => {
      resolver = jest.fn().mockResolvedValue(packagesListQuery());
      mountComponent({ resolver });

      return waitForDebouncedApollo();
    });

    it('exists and has the right props', () => {
      expect(findListComponent().props()).toMatchObject({
        list: expect.arrayContaining([expect.objectContaining({ id: packageData().id })]),
        isLoading: false,
        pageInfo: expect.objectContaining({ endCursor: pagination().endCursor }),
      });
    });

    it('when list emits next-page fetches the next set of records', () => {
      findListComponent().vm.$emit('next-page');

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ after: pagination().endCursor, first: GRAPHQL_PAGE_SIZE }),
      );
    });

    it('when list emits prev-page fetches the prev set of records', () => {
      findListComponent().vm.$emit('prev-page');

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ before: pagination().startCursor, last: GRAPHQL_PAGE_SIZE }),
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
      resolver = jest.fn().mockResolvedValue(packagesListQuery({ type }));
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

  describe('empty state', () => {
    beforeEach(() => {
      const resolver = jest.fn().mockResolvedValue(packagesListQuery({ extend: { nodes: [] } }));
      mountComponent({ resolver });

      return waitForDebouncedApollo();
    });
    it('generate the correct empty list link', () => {
      const link = findListComponent().findComponent(GlLink);

      expect(link.attributes('href')).toBe(defaultProvide.emptyListHelpUrl);
      expect(link.text()).toBe('publish and share your packages');
    });

    it('includes the right content on the default tab', () => {
      expect(findEmptyState().text()).toContain(PackageListApp.i18n.emptyPageTitle);
    });
  });

  describe('filter without results', () => {
    beforeEach(async () => {
      mountComponent();

      await waitForDebouncedApollo();

      findSearch().vm.$emit('update', searchPayload);

      return nextTick();
    });

    it('should show specific empty message', () => {
      expect(findEmptyState().text()).toContain(PackageListApp.i18n.noResultsTitle);
      expect(findEmptyState().text()).toContain(PackageListApp.i18n.widenFilters);
    });
  });

  describe('delete package', () => {
    it('exists and has the correct props', async () => {
      mountComponent();

      await waitForDebouncedApollo();

      expect(findDeletePackage().props()).toMatchObject({
        refetchQueries: [{ query: getPackagesQuery, variables: {} }],
        showSuccessAlert: true,
      });
    });

    it('deletePackage is bound to package-list package:delete event', async () => {
      mountComponent();

      await waitForDebouncedApollo();

      findListComponent().vm.$emit('package:delete', { id: 1 });

      expect(findDeletePackage().emitted('start')).toEqual([[]]);
    });

    it('start and end event set loading correctly', async () => {
      mountComponent();

      await waitForDebouncedApollo();

      findDeletePackage().vm.$emit('start');

      await nextTick();

      expect(findListComponent().props('isLoading')).toBe(true);

      findDeletePackage().vm.$emit('end');

      await nextTick();

      expect(findListComponent().props('isLoading')).toBe(false);
    });
  });
});
