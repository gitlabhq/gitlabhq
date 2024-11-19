import { GlButton, GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import ListPage from '~/packages_and_registries/package_registry/pages/list.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/list/package_title.vue';
import PackageSearch from '~/packages_and_registries/package_registry/components/list/package_search.vue';
import OriginalPackageList from '~/packages_and_registries/package_registry/components/list/packages_list.vue';
import DeletePackages from '~/packages_and_registries/package_registry/components/functional/delete_packages.vue';
import PackageErrorsCount from '~/packages_and_registries/package_registry/components/list/package_errors_count.vue';
import {
  GRAPHQL_PAGE_SIZE,
  EMPTY_LIST_HELP_URL,
  PACKAGE_HELP_URL,
} from '~/packages_and_registries/package_registry/constants';
import PersistedPagination from '~/packages_and_registries/shared/components/persisted_pagination.vue';
import getPackagesQuery from '~/packages_and_registries/package_registry/graphql/queries/get_packages.query.graphql';
import getGroupPackageSettings from '~/packages_and_registries/package_registry/graphql/queries/get_group_package_settings.query.graphql';
import destroyPackagesMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_packages.mutation.graphql';
import {
  packagesListQuery,
  groupPackageSettingsQuery,
  groupPackageSettingsQueryForGroup,
  packageData,
  pagination,
} from '../mock_data';

jest.mock('~/alert');

describe('PackagesListApp', () => {
  let wrapper;
  let apolloProvider;

  const defaultProvide = {
    emptyListIllustration: 'emptyListIllustration',
    isGroupPage: true,
    fullPath: 'gitlab-org',
    settingsPath: 'settings-path',
    canDeletePackages: true,
  };

  const PackageList = {
    name: 'package-list',
    template: '<div><slot name="empty-state"></slot></div>',
    props: OriginalPackageList.props,
  };
  const GlLoadingIcon = { name: 'gl-loading-icon', template: '<div>loading</div>' };

  const searchPayload = {
    sort: 'VERSION_DESC',
    filters: {
      packageName: 'foo',
      packageType: 'CONAN',
      packageVersion: '1.0.1',
      packageStatus: 'DEFAULT',
    },
  };

  const findPackageTitle = () => wrapper.findComponent(PackageTitle);
  const findSearch = () => wrapper.findComponent(PackageSearch);
  const findPackageErrorsCount = () => wrapper.findComponent(PackageErrorsCount);
  const findListComponent = () => wrapper.findComponent(PackageList);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findDeletePackages = () => wrapper.findComponent(DeletePackages);
  const findSettingsLink = () => wrapper.findComponent(GlButton);
  const findPagination = () => wrapper.findComponent(PersistedPagination);

  const mountComponent = ({
    resolver = jest.fn().mockResolvedValue(packagesListQuery()),
    groupPackageSettingsResolver = jest.fn().mockResolvedValue(groupPackageSettingsQueryForGroup()),
    mutationResolver,
    provide = defaultProvide,
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getPackagesQuery, resolver],
      [getGroupPackageSettings, groupPackageSettingsResolver],
      [destroyPackagesMutation, mutationResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ListPage, {
      apolloProvider,
      provide,
      stubs: {
        GlEmptyState,
        GlLoadingIcon,
        GlSprintf,
        GlLink,
        PackageTitle,
        PackageList,
        DeletePackages,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const waitForFirstRequest = () => {
    // emit a search update so the query is executed
    findSearch().vm.$emit('update', { sort: 'NAME_DESC', filters: {} });
    return waitForPromises();
  };

  it('does not execute the query without sort being set', () => {
    const resolver = jest.fn().mockResolvedValue(packagesListQuery());

    mountComponent({ resolver });

    expect(resolver).not.toHaveBeenCalled();
  });

  it('has persisted pagination', async () => {
    const resolver = jest.fn().mockResolvedValue(packagesListQuery());

    mountComponent({ resolver });
    await waitForFirstRequest();

    expect(findPagination().props('pagination')).toEqual(pagination());
  });

  it('has a package title', async () => {
    mountComponent();

    await waitForFirstRequest();

    expect(findPackageTitle().exists()).toBe(true);
    expect(findPackageTitle().props()).toMatchObject({
      count: 2,
      helpUrl: PACKAGE_HELP_URL,
    });
  });

  describe('link to settings', () => {
    describe('when settings path is not provided', () => {
      beforeEach(() => {
        mountComponent({
          provide: {
            ...defaultProvide,
            settingsPath: '',
          },
        });
      });

      it('is not rendered', () => {
        expect(findSettingsLink().exists()).toBe(false);
      });
    });

    describe('when settings path is provided', () => {
      const label = 'Configure in settings';

      beforeEach(() => {
        mountComponent();
      });

      it('is rendered', () => {
        expect(findSettingsLink().exists()).toBe(true);
      });

      it('has the right icon', () => {
        expect(findSettingsLink().props('icon')).toBe('settings');
      });

      it('has the right attributes', () => {
        expect(findSettingsLink().attributes()).toMatchObject({
          'aria-label': label,
          href: defaultProvide.settingsPath,
        });
      });

      it('sets tooltip with right label', () => {
        const tooltip = getBinding(findSettingsLink().element, 'gl-tooltip');

        expect(tooltip.value).toBe(label);
      });
    });
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

      await waitForPromises();

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
    });

    it('exists and has the right props', async () => {
      findSearch().vm.$emit('update', searchPayload);
      await waitForPromises();

      expect(findListComponent().props()).toMatchObject({
        list: expect.arrayContaining([expect.objectContaining({ id: packageData().id })]),
        isLoading: false,
        groupSettings: expect.objectContaining({
          mavenPackageRequestsForwarding: true,
          npmPackageRequestsForwarding: true,
          pypiPackageRequestsForwarding: true,
        }),
      });
    });

    it('renders PackageErrorsCount component', async () => {
      findSearch().vm.$emit('update', searchPayload);
      await waitForPromises();

      expect(findPackageErrorsCount().exists()).toBe(true);
    });

    describe('when packageStatus filter is set to error', () => {
      beforeEach(async () => {
        findSearch().vm.$emit('update', { filters: { packageStatus: 'error' } });
        await nextTick();
      });

      it('does not render PackageErrorsCount component', () => {
        expect(findPackageErrorsCount().exists()).toBe(false);
      });
    });

    it('when pagination emits next event fetches the next set of records', async () => {
      await waitForFirstRequest();
      findPagination().vm.$emit('next');
      await waitForPromises();

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ after: pagination().endCursor, first: GRAPHQL_PAGE_SIZE }),
      );
    });

    it('when pagination emits prev event fetches the prev set of records', async () => {
      await waitForFirstRequest();
      findPagination().vm.$emit('prev');
      await waitForPromises();

      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({
          first: null,
          before: pagination().startCursor,
          last: GRAPHQL_PAGE_SIZE,
        }),
      );
    });
  });

  describe('when canDeletePackages is false does not request group package settings query', () => {
    const groupPackageSettingsResolver = jest
      .fn()
      .mockResolvedValue(groupPackageSettingsQueryForGroup());
    beforeEach(() => {
      mountComponent({
        groupPackageSettingsResolver,
        provide: {
          ...defaultProvide,
          canDeletePackages: false,
        },
      });

      return waitForFirstRequest();
    });

    it('does not request group package settings query', () => {
      expect(groupPackageSettingsResolver).not.toHaveBeenCalled();
    });
  });

  describe.each`
    type                 | sortType
    ${WORKSPACE_PROJECT} | ${'sort'}
    ${WORKSPACE_GROUP}   | ${'groupSort'}
  `('$type query', ({ type, sortType }) => {
    let groupPackageSettingsResolver;
    let provide;
    let resolver;

    const isGroupPage = type === WORKSPACE_GROUP;

    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
      provide = { ...defaultProvide, isGroupPage };
      resolver = jest.fn().mockResolvedValue(packagesListQuery({ type }));

      const response = isGroupPage
        ? groupPackageSettingsQueryForGroup()
        : groupPackageSettingsQuery();
      groupPackageSettingsResolver = jest.fn().mockResolvedValue(response);
      mountComponent({
        provide,
        resolver,
        groupPackageSettingsResolver,
      });
      return waitForFirstRequest();
    });

    it('succeeds', () => {
      expect(findPackageTitle().props('count')).toBe(2);
    });

    it('calls the resolver with the right parameters', () => {
      expect(resolver).toHaveBeenCalledWith(
        expect.objectContaining({ isGroupPage, [sortType]: 'NAME_DESC' }),
      );
    });

    it('calls the group packageSettings resolver with the right parameters', () => {
      expect(groupPackageSettingsResolver).toHaveBeenCalledWith({
        fullPath: provide.fullPath,
        isGroupPage,
      });
    });

    it('expects not to call sentry', () => {
      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    it('list component has group settings prop set', () => {
      expect(findListComponent().props()).toMatchObject({
        groupSettings: expect.objectContaining({
          mavenPackageRequestsForwarding: true,
          npmPackageRequestsForwarding: true,
          pypiPackageRequestsForwarding: true,
        }),
      });
    });

    describe('when group package settings query fails', () => {
      beforeEach(() => {
        groupPackageSettingsResolver = jest.fn().mockRejectedValue(new Error('error'));
        mountComponent({
          provide,
          resolver,
          groupPackageSettingsResolver,
        });
        return waitForFirstRequest();
      });

      it('captures error in Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalled();
      });
    });
  });

  describe.each`
    description         | resolverResponse
    ${'empty response'} | ${packagesListQuery({ extend: { packages: { nodes: [], count: 0, pageInfo: {}, __typename: 'PackageConnection' } } })}
    ${'error response'} | ${{ data: { group: null } }}
  `(`$description renders empty state`, ({ resolverResponse }) => {
    const groupPackageSettingsResolver = jest
      .fn()
      .mockResolvedValue(groupPackageSettingsQueryForGroup());

    beforeEach(() => {
      const resolver = jest.fn().mockResolvedValue(resolverResponse);
      mountComponent({ resolver, groupPackageSettingsResolver });

      return waitForFirstRequest();
    });

    it('generate the correct empty list link', () => {
      const link = findListComponent().findComponent(GlLink);

      expect(link.attributes('href')).toBe(EMPTY_LIST_HELP_URL);
      expect(link.text()).toBe('publish and share your packages');
    });

    it('includes the right content on the default tab', () => {
      expect(findEmptyState().text()).toContain(ListPage.i18n.emptyPageTitle);
    });

    it('does not request for group package settings', () => {
      expect(groupPackageSettingsResolver).not.toHaveBeenCalled();
    });
  });

  describe('filter without results', () => {
    beforeEach(async () => {
      mountComponent();

      await waitForFirstRequest();

      findSearch().vm.$emit('update', {
        sort: 'VERSION_DESC',
        filters: {
          packageName: 'test',
        },
      });

      return nextTick();
    });

    it('should show specific empty message', () => {
      expect(findEmptyState().text()).toContain(ListPage.i18n.noResultsTitle);
      expect(findEmptyState().text()).toContain(ListPage.i18n.widenFilters);
    });
  });

  describe('delete packages', () => {
    it('exists and has the correct props', async () => {
      mountComponent();

      await waitForFirstRequest();

      expect(findDeletePackages().props()).toMatchObject({
        refetchQueries: [{ query: getPackagesQuery, variables: {} }],
        showSuccessAlert: true,
      });
    });

    it('deletePackages is bound to package-list delete event', async () => {
      mountComponent();

      await waitForFirstRequest();

      findListComponent().vm.$emit('delete', [{ id: 1 }]);

      expect(findDeletePackages().emitted('start')).toEqual([[]]);
    });

    it('deletePackages is bound to package-errors-count delete event', async () => {
      mountComponent();

      await waitForFirstRequest();

      findPackageErrorsCount().vm.$emit('confirm-delete', [{ id: 1 }]);

      expect(findDeletePackages().emitted('start')).toHaveLength(1);
    });

    it('start and end event set loading correctly', async () => {
      mountComponent();

      await waitForFirstRequest();

      findDeletePackages().vm.$emit('start');

      await nextTick();

      expect(findListComponent().props('isLoading')).toBe(true);

      findDeletePackages().vm.$emit('end');

      await nextTick();

      expect(findListComponent().props('isLoading')).toBe(false);
    });
  });
});
