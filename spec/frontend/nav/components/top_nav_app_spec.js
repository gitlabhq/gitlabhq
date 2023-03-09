import { GlNavItemDropdown } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { mockTracking } from 'helpers/tracking_helper';
import TopNavApp from '~/nav/components/top_nav_app.vue';
import TopNavDropdownMenu from '~/nav/components/top_nav_dropdown_menu.vue';
import { TEST_NAV_DATA } from '../mock_data';

describe('~/nav/components/top_nav_app.vue', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(TopNavApp, {
      propsData: {
        navData: TEST_NAV_DATA,
      },
    });
  };

  const createComponentShallow = () => {
    wrapper = shallowMount(TopNavApp, {
      propsData: {
        navData: TEST_NAV_DATA,
      },
    });
  };

  const findNavItemDropdown = () => wrapper.findComponent(GlNavItemDropdown);
  const findNavItemDropdowToggle = () => findNavItemDropdown().find('.js-top-nav-dropdown-toggle');
  const findMenu = () => wrapper.findComponent(TopNavDropdownMenu);

  describe('default', () => {
    beforeEach(() => {
      createComponentShallow();
    });

    it('renders nav item dropdown', () => {
      expect(findNavItemDropdown().attributes('href')).toBeUndefined();
      expect(findNavItemDropdown().attributes()).toMatchObject({
        icon: '',
        text: '',
        'no-flip': '',
        'no-caret': '',
      });
    });

    it('renders top nav dropdown menu', () => {
      expect(findMenu().props()).toStrictEqual({
        primary: TEST_NAV_DATA.primary,
        secondary: TEST_NAV_DATA.secondary,
        views: TEST_NAV_DATA.views,
      });
    });
  });

  describe('tracking', () => {
    it('emits a tracking event when the toggle is clicked', () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      createComponent();

      findNavItemDropdowToggle().trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_nav', {
        label: 'hamburger_menu',
        property: 'navigation_top',
      });
    });
  });
});
