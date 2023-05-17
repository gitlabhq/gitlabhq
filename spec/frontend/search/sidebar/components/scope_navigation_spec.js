import { GlNav, GlNavItem, GlIcon } from '@gitlab/ui';
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

  const getterSpies = {
    currentScope: jest.fn(() => 'issues'),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        navigation: MOCK_NAVIGATION,
        ...initialState,
      },
      actions: actionSpies,
      getters: getterSpies,
    });

    wrapper = shallowMount(ScopeNavigation, {
      store,
    });
  };

  const findNavElement = () => wrapper.find('nav');
  const findGlNav = () => wrapper.findComponent(GlNav);
  const findGlNavItems = () => wrapper.findAllComponents(GlNavItem);
  const findGlNavItemActive = () => wrapper.find('[active=true]');
  const findGlNavItemActiveLabel = () => findGlNavItemActive().find('[data-testid="label"]');
  const findGlNavItemActiveCount = () => findGlNavItemActive().find('[data-testid="count"]');

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

    it('has all proper links', () => {
      const linkAtPosition = 3;
      const { link } = MOCK_NAVIGATION[Object.keys(MOCK_NAVIGATION)[linkAtPosition]];

      expect(findGlNavItems().at(linkAtPosition).attributes('href')).toBe(link);
    });
  });

  describe('scope navigation sets proper state with url scope set', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has correct active item', () => {
      expect(findGlNavItemActive().exists()).toBe(true);
      expect(findGlNavItemActiveLabel().text()).toBe('Issues');
    });

    it('has correct active item count', () => {
      expect(findGlNavItemActiveCount().text()).toBe('2.4K');
    });

    it('does not have plus sign after count text', () => {
      expect(findGlNavItemActive().findComponent(GlIcon).exists()).toBe(false);
    });

    it('has count is highlighted correctly', () => {
      expect(findGlNavItemActiveCount().classes('gl-text-gray-900')).toBe(true);
    });
  });

  describe('scope navigation sets proper state with NO url scope set', () => {
    beforeEach(() => {
      getterSpies.currentScope = jest.fn(() => 'projects');
      createComponent({
        urlQuery: {},
        navigation: {
          ...MOCK_NAVIGATION,
          projects: {
            ...MOCK_NAVIGATION.projects,
            active: true,
          },
          issues: {
            ...MOCK_NAVIGATION.issues,
            active: false,
          },
        },
      });
    });

    it('has correct active item', () => {
      expect(findGlNavItemActive().exists()).toBe(true);
      expect(findGlNavItemActiveLabel().text()).toBe('Projects');
    });

    it('has correct active item count', () => {
      expect(findGlNavItemActiveCount().text()).toBe('10K');
    });

    it('has correct active item count and over limit sign', () => {
      expect(findGlNavItemActive().findComponent(GlIcon).exists()).toBe(true);
    });
  });

  describe.each`
    searchTherm | hasBeenCalled
    ${null}     | ${0}
    ${'test'}   | ${1}
  `('fetchSidebarCount', ({ searchTherm, hasBeenCalled }) => {
    beforeEach(() => {
      createComponent({
        urlQuery: {
          search: searchTherm,
        },
      });
    });

    it('is only called when search term is set', () => {
      expect(actionSpies.fetchSidebarCount).toHaveBeenCalledTimes(hasBeenCalled);
    });
  });
});
