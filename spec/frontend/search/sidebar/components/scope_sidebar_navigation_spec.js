import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import sidebarEventHub from '~/super_sidebar/event_hub';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { MOCK_QUERY, MOCK_NAVIGATION, MOCK_NAVIGATION_ITEMS } from '../../mock_data';

Vue.use(Vuex);

const MOCK_NAVIGATION_ENTRIES = Object.entries(MOCK_NAVIGATION);

describe('ScopeSidebarNavigation', () => {
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

    wrapper = mount(ScopeSidebarNavigation, {
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
    findNavItemActive().find('[class="gl-flex-grow-1 gl-text-gray-900"]');

  describe('scope navigation', () => {
    beforeEach(() => {
      jest.spyOn(sidebarEventHub, '$emit');
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
      expect(findNavItems()).toHaveLength(MOCK_NAVIGATION_ENTRIES.length);
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
