import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import Vue from 'vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert, VARIANT_INFO } from '~/alert';
import * as commonUtils from '~/lib/utils/common_utils';
import PackageListApp from '~/packages_and_registries/infrastructure_registry/list/components/packages_list_app.vue';
import { DELETE_PACKAGE_SUCCESS_MESSAGE } from '~/packages_and_registries/infrastructure_registry/list/constants';
import { useInfrastructureList } from '~/packages_and_registries/infrastructure_registry/list/stores';
import { SHOW_DELETE_SUCCESS_ALERT } from '~/packages_and_registries/shared/constants';

import * as packageUtils from '~/packages_and_registries/shared/utils';
import InfrastructureSearch from '~/packages_and_registries/infrastructure_registry/list/components/infrastructure_search.vue';
import InfrastructureTitle from '~/packages_and_registries/infrastructure_registry/list/components/infrastructure_title.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/alert');

Vue.use(PiniaVuePlugin);

describe('packages_list_app', () => {
  let wrapper;
  let pinia;
  let store;

  const PackageList = {
    name: 'package-list',
    template: '<div><slot name="empty-state"></slot></div>',
  };
  const GlLoadingIcon = { name: 'gl-loading-icon', template: '<div>loading</div>' };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findListComponent = () => wrapper.findComponent(PackageList);
  const findInfrastructureSearch = () => wrapper.findComponent(InfrastructureSearch);
  const findInfrastructureTitle = () => wrapper.findComponent(InfrastructureTitle);

  const createStore = ({ filter = [], packageCount = 0 } = {}) => {
    pinia = createTestingPinia();
    store = useInfrastructureList();
    store.$patch({
      isLoading: false,
      filter,
      pagination: { total: packageCount },
    });
  };

  const mountComponent = ({ isGroupPage = false } = {}) => {
    wrapper = shallowMount(PackageListApp, {
      pinia,
      provide: {
        isGroupPage,
        emptyListIllustration: 'helpSvg',
        resourceId: 'project_id',
      },
      stubs: {
        GlEmptyState,
        GlLoadingIcon,
        PackageList,
        GlSprintf,
        GlLink,
      },
    });
  };

  beforeEach(() => {
    createStore();
    jest.spyOn(packageUtils, 'getQueryParams').mockReturnValue({});
    mountComponent();
  });

  it('renders', () => {
    createStore({ packageCount: 1 });
    mountComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('calls requestPackagesList on page:changed', () => {
    const list = findListComponent();
    list.vm.$emit('page:changed', 1);
    expect(store.requestPackagesList).toHaveBeenCalledWith({
      page: 1,
      isGroupPage: false,
      resourceId: 'project_id',
    });
  });

  it('calls requestDeletePackage on package:delete', () => {
    const payload = {
      _links: {
        delete_api_path: 'foo',
      },
    };
    const list = findListComponent();
    list.vm.$emit('package:delete', payload);

    expect(store.requestDeletePackage).toHaveBeenCalledWith({
      ...payload,
      isGroupPage: false,
      resourceId: 'project_id',
    });
  });

  it('calls setSorting, setFilter, and requestPackagesList once on render', () => {
    expect(store.setSorting).toHaveBeenCalledTimes(1);
    expect(store.setSorting).toHaveBeenCalledWith(expect.any(Object));
    expect(store.setFilter).toHaveBeenCalledTimes(1);
    expect(store.setFilter).toHaveBeenCalledWith(expect.any(Array));
    expect(store.requestPackagesList).toHaveBeenCalledTimes(1);
    expect(store.requestPackagesList).toHaveBeenCalledWith({
      isGroupPage: false,
      resourceId: 'project_id',
    });
  });

  describe('url query string handling', () => {
    const defaultQueryParamsMock = {
      search: [1, 2],
      type: 'npm',
      sort: 'asc',
      orderBy: 'created',
    };

    beforeEach(() => {
      createStore();
      jest.spyOn(packageUtils, 'getQueryParams').mockReturnValue(defaultQueryParamsMock);
    });

    it('calls setSorting with the query string based sorting', () => {
      mountComponent();

      expect(store.setSorting).toHaveBeenCalledWith({
        orderBy: defaultQueryParamsMock.orderBy,
        sort: defaultQueryParamsMock.sort,
      });
    });

    it('calls setFilter with the query string based filters', () => {
      mountComponent();

      expect(store.setFilter).toHaveBeenCalledWith([
        { type: 'type', value: { data: defaultQueryParamsMock.type } },
        { type: FILTERED_SEARCH_TERM, value: { data: defaultQueryParamsMock.search[0] } },
        { type: FILTERED_SEARCH_TERM, value: { data: defaultQueryParamsMock.search[1] } },
      ]);
    });

    it('calls setSorting and setFilter with the results of extractFilterAndSorting', () => {
      jest
        .spyOn(packageUtils, 'extractFilterAndSorting')
        .mockReturnValue({ filters: ['foo'], sorting: { sort: 'desc' } });

      mountComponent();

      expect(store.setSorting).toHaveBeenCalledWith({ sort: 'desc' });
      expect(store.setFilter).toHaveBeenCalledWith(['foo']);
    });
  });

  describe('empty state', () => {
    const heading = () => findEmptyState().find('h2');

    it('generate the correct empty list link', () => {
      const link = findListComponent().findComponent(GlLink);

      expect(link.attributes('href')).toBe(
        helpPagePath('user/packages/terraform_module_registry/_index'),
      );
      expect(link.text()).toBe('publish and share your packages');
    });

    it('includes the right content on the default tab', () => {
      expect(heading().text()).toBe('You have no Terraform modules in your project');
    });

    it('does not show infrastructure registry title', () => {
      expect(findInfrastructureTitle().exists()).toBe(false);
    });

    describe('when group page', () => {
      beforeEach(() => {
        createStore();
        mountComponent({ isGroupPage: true });
      });

      it('includes the right content', () => {
        expect(heading().text()).toBe('You have no Terraform modules in your group');
      });
    });
  });

  describe('filter without results', () => {
    beforeEach(() => {
      createStore({ filter: [{ type: 'something' }] });
      mountComponent();
    });

    it('should show specific empty message', () => {
      expect(findEmptyState().text()).toContain('Sorry, your filter produced no results');
      expect(findEmptyState().text()).toContain(
        'To widen your search, change or remove the filters above',
      );
    });
  });

  describe('search', () => {
    describe('with no packages', () => {
      it('does not exist', () => {
        expect(findInfrastructureSearch().exists()).toBe(false);
      });
    });

    describe('with packages', () => {
      beforeEach(() => {
        createStore({ packageCount: 1 });
        mountComponent();
      });

      it('exists', () => {
        expect(findInfrastructureSearch().exists()).toBe(true);
      });

      it('shows infrastructure registry title', () => {
        expect(findInfrastructureTitle().exists()).toBe(true);
      });

      it('on update fetches data from the store', () => {
        store.requestPackagesList.mockClear();

        findInfrastructureSearch().vm.$emit('update');

        expect(store.requestPackagesList).toHaveBeenCalledWith({
          isGroupPage: false,
          resourceId: 'project_id',
        });
      });
    });
  });

  describe('delete alert handling', () => {
    const originalLocation = window.location.href;
    const search = `?${SHOW_DELETE_SUCCESS_ALERT}=true`;

    beforeEach(() => {
      createStore();
      jest.spyOn(commonUtils, 'historyReplaceState').mockImplementation(() => {});
      setWindowLocation(search);
    });

    afterEach(() => {
      setWindowLocation(originalLocation);
    });

    it(`creates an alert if the query string contains ${SHOW_DELETE_SUCCESS_ALERT}`, () => {
      mountComponent();

      expect(createAlert).toHaveBeenCalledWith({
        message: DELETE_PACKAGE_SUCCESS_MESSAGE,
        variant: VARIANT_INFO,
      });
    });

    it('calls historyReplaceState with a clean url', () => {
      mountComponent();

      expect(commonUtils.historyReplaceState).toHaveBeenCalledWith(originalLocation);
    });

    it(`does nothing if the query string does not contain ${SHOW_DELETE_SUCCESS_ALERT}`, () => {
      setWindowLocation('?');
      mountComponent();

      expect(createAlert).not.toHaveBeenCalled();
      expect(commonUtils.historyReplaceState).not.toHaveBeenCalled();
    });
  });
});
