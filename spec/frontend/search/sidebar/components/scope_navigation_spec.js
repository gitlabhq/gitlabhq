import { GlNav, GlNavItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_QUERY, MOCK_NAVIGATION } from 'jest/search/mock_data';
import ScopeNavigation from '~/search/sidebar/components/scope_navigation.vue';

Vue.use(Vuex);

describe('ScopeNavigation', () => {
  let wrapper;

  const actionSpies = {
    fetchSidebarCount: jest.fn(),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        navigation: MOCK_NAVIGATION,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(ScopeNavigation, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findNavElement = () => wrapper.find('nav');
  const findGlNav = () => wrapper.findComponent(GlNav);
  const findGlNavItems = () => wrapper.findAllComponents(GlNavItem);
  const findGlNavItemActive = () => findGlNavItems().wrappers.filter((w) => w.attributes('active'));
  const findGlNavItemActiveCount = () => findGlNavItemActive().at(0).findAll('span').at(1);

  describe('scope navigation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders section', () => {
      expect(findNavElement().exists()).toBe(true);
    });

    it('renders nav component', () => {
      expect(findGlNav().exists()).toBe(true);
    });

    it('renders all nav item components', () => {
      expect(findGlNavItems()).toHaveLength(9);
    });

    it('nav items have proper links', () => {
      const linkAtPosition = 3;
      const { link } = MOCK_NAVIGATION[Object.keys(MOCK_NAVIGATION)[linkAtPosition]];

      expect(findGlNavItems().at(linkAtPosition).attributes('href')).toBe(link);
    });
  });

  describe('scope navigation sets proper state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets proper class to active item', () => {
      expect(findGlNavItemActive()).toHaveLength(1);
    });

    it('active item', () => {
      expect(findGlNavItemActiveCount().text()).toBe('2.4K');
    });
  });
});
