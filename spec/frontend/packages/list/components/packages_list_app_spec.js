import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlEmptyState, GlTab, GlTabs, GlSprintf, GlLink } from '@gitlab/ui';
import PackageListApp from '~/packages/list/components/packages_list_app.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('packages_list_app', () => {
  let wrapper;
  let store;

  const PackageList = {
    name: 'package-list',
    template: '<div><slot name="empty-state"></slot></div>',
  };
  const GlLoadingIcon = { name: 'gl-loading-icon', template: '<div>loading</div>' };

  const emptyListHelpUrl = 'helpUrl';
  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findListComponent = () => wrapper.find(PackageList);
  const findTabComponent = (index = 0) => wrapper.findAll(GlTab).at(index);

  const createStore = (filterQuery = '') => {
    store = new Vuex.Store({
      state: {
        isLoading: false,
        config: {
          resourceId: 'project_id',
          emptyListIllustration: 'helpSvg',
          emptyListHelpUrl,
        },
        filterQuery,
      },
    });
    store.dispatch = jest.fn();
  };

  const mountComponent = () => {
    wrapper = shallowMount(PackageListApp, {
      localVue,
      store,
      stubs: {
        GlEmptyState,
        GlLoadingIcon,
        PackageList,
        GlTab,
        GlTabs,
        GlSprintf,
        GlLink,
      },
    });
  };

  beforeEach(() => {
    createStore();
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('empty state', () => {
    it('generate the correct empty list link', () => {
      const link = findListComponent().find(GlLink);

      expect(link.attributes('href')).toBe(emptyListHelpUrl);
      expect(link.text()).toBe('publish and share your packages');
    });

    it('includes the right content on the default tab', () => {
      const heading = findEmptyState().find('h1');

      expect(heading.text()).toBe('There are no packages yet');
    });
  });

  it('call requestPackagesList on page:changed', () => {
    const list = findListComponent();
    list.vm.$emit('page:changed', 1);
    expect(store.dispatch).toHaveBeenCalledWith('requestPackagesList', { page: 1 });
  });

  it('call requestDeletePackage on package:delete', () => {
    const list = findListComponent();
    list.vm.$emit('package:delete', 'foo');
    expect(store.dispatch).toHaveBeenCalledWith('requestDeletePackage', 'foo');
  });

  it('calls requestPackagesList on sort:changed', () => {
    const list = findListComponent();
    list.vm.$emit('sort:changed');
    expect(store.dispatch).toHaveBeenCalledWith('requestPackagesList');
  });

  describe('tab change', () => {
    it('calls requestPackagesList when all tab is clicked', () => {
      findTabComponent().trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('requestPackagesList');
    });

    it('calls requestPackagesList when a package type tab is clicked', () => {
      findTabComponent(1).trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('requestPackagesList');
    });
  });

  describe('filter without results', () => {
    beforeEach(() => {
      createStore('foo');
      mountComponent();
    });

    it('should show specific empty message', () => {
      expect(findEmptyState().text()).toContain('Sorry, your filter produced no results');
      expect(findEmptyState().text()).toContain(
        'To widen your search, change or remove the filters above',
      );
    });
  });
});
