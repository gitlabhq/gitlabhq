import { shallowMount } from '@vue/test-utils';
import SuperTopbar from '~/super_sidebar/components/super_topbar.vue';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import UserCounts from '~/super_sidebar/components/user_counts.vue';
import UserMenu from '~/super_sidebar/components/user_menu.vue';

describe('SuperTopbar', () => {
  let wrapper;

  const findBrandLogo = () => wrapper.findComponent(BrandLogo);
  const findUserCounts = () => wrapper.findComponent(UserCounts);
  const findUserMenu = () => wrapper.findComponent(UserMenu);

  const defaultProps = {
    sidebarData: {
      logo_url: 'https://example.com/logo.png',
      is_logged_in: true,
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SuperTopbar, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the header element with correct `super-topbar` class', () => {
      expect(wrapper.find('header').classes()).toContain('super-topbar');
    });

    it('renders BrandLogo component with correct props', () => {
      expect(findBrandLogo().props('logoUrl')).toBe(defaultProps.sidebarData.logo_url);
    });

    it('renders UserMenu when user is logged in', () => {
      expect(findUserMenu().props('data')).toEqual(defaultProps.sidebarData);
    });

    it('does not render UserMenu when user is not logged in', () => {
      createComponent({ sidebarData: { is_logged_in: false } });

      expect(findUserMenu().exists()).toBe(false);
    });

    it('renders UserCounts component when user is logged in', () => {
      expect(findUserCounts().props('sidebarData')).toEqual(defaultProps.sidebarData);
    });

    it('does not render UserCounts when user is not logged in', () => {
      createComponent({ sidebarData: { is_logged_in: false } });

      expect(findUserCounts().exists()).toBe(false);
    });
  });
});
