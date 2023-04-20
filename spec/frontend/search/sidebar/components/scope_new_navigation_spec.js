import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import ScopeNewNavigation from '~/search/sidebar/components/scope_new_navigation.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { MOCK_QUERY, MOCK_NAVIGATION, MOCK_NAVIGATION_ITEMS } from '../../mock_data';

Vue.use(Vuex);

describe('ScopeNewNavigation', () => {
  let wrapper;

  const actionSpies = {
    fetchSidebarCount: jest.fn(),
  };

  const getterSpies = {
    currentScope: jest.fn(() => 'issues'),
    navigationItems: jest.fn(() => MOCK_NAVIGATION_ITEMS),
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

    wrapper = shallowMount(ScopeNewNavigation, {
      store,
      stubs: {
        NavItem,
      },
    });
  };

  const findNavElement = () => wrapper.findComponent('nav');
  const findNavItems = () => wrapper.findAllComponents(NavItem);
  const findNavItemActive = () => wrapper.find('[aria-current=page]');
  const findNavItemActiveLabel = () =>
    findNavItemActive().find('[class="gl-pr-3 gl-text-gray-900 gl-truncate-end"]');

  describe('scope navigation', () => {
    beforeEach(() => {
      createComponent({ urlQuery: { ...MOCK_QUERY, search: 'test' } });
    });

    it('renders section', () => {
      expect(findNavElement().exists()).toBe(true);
    });

    it('calls proper action when rendered', async () => {
      await nextTick();
      expect(actionSpies.fetchSidebarCount).toHaveBeenCalled();
    });

    it('renders all nav item components', () => {
      expect(findNavItems()).toHaveLength(9);
    });

    it('has all proper links', () => {
      const linkAtPosition = 3;
      const { link } = MOCK_NAVIGATION[Object.keys(MOCK_NAVIGATION)[linkAtPosition]];

      expect(findNavItems().at(linkAtPosition).findComponent('a').attributes('href')).toBe(link);
    });
  });

  describe('scope navigation sets proper state with url scope set', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has correct active item', () => {
      expect(findNavItemActive().exists()).toBe(true);
      expect(findNavItemActiveLabel().text()).toBe('Issues');
    });
  });
});
