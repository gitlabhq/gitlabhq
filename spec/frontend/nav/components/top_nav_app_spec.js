import { GlNavItemDropdown, GlTooltip } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import TopNavApp from '~/nav/components/top_nav_app.vue';
import TopNavDropdownMenu from '~/nav/components/top_nav_dropdown_menu.vue';
import { TEST_NAV_DATA } from '../mock_data';

describe('~/nav/components/top_nav_app.vue', () => {
  let wrapper;

  const createComponent = (mountFn = shallowMount) => {
    wrapper = mountFn(TopNavApp, {
      propsData: {
        navData: TEST_NAV_DATA,
      },
    });
  };

  const findNavItemDropdown = () => wrapper.findComponent(GlNavItemDropdown);
  const findMenu = () => wrapper.findComponent(TopNavDropdownMenu);
  const findTooltip = () => wrapper.findComponent(GlTooltip);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders nav item dropdown', () => {
      expect(findNavItemDropdown().attributes('href')).toBeUndefined();
      expect(findNavItemDropdown().attributes()).toMatchObject({
        icon: 'dot-grid',
        text: TEST_NAV_DATA.activeTitle,
        'no-flip': '',
      });
    });

    it('renders top nav dropdown menu', () => {
      expect(findMenu().props()).toStrictEqual({
        primary: TEST_NAV_DATA.primary,
        secondary: TEST_NAV_DATA.secondary,
        views: TEST_NAV_DATA.views,
      });
    });

    it('renders tooltip', () => {
      expect(findTooltip().attributes()).toMatchObject({
        'boundary-padding': '0',
        placement: 'right',
        title: TopNavApp.TOOLTIP,
      });
    });
  });

  describe('when full mounted', () => {
    beforeEach(() => {
      createComponent(mount);
    });

    it('has dropdown toggle as tooltip target', () => {
      const targetFn = findTooltip().props('target');

      expect(targetFn()).toBe(wrapper.find('.js-top-nav-dropdown-toggle').element);
    });
  });
});
