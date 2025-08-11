import { shallowMount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import SuperTopbar from '~/super_sidebar/components/super_topbar.vue';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import UserCounts from '~/super_sidebar/components/user_counts.vue';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import { sidebarData as mockSidebarData } from '../mock_data';

describe('SuperTopbar', () => {
  let wrapper;

  const findBrandLogo = () => wrapper.findComponent(BrandLogo);
  const findCreateMenu = () => wrapper.findComponent(CreateMenu);
  const findNextBadge = () => wrapper.findComponent(GlBadge);
  const findUserCounts = () => wrapper.findComponent(UserCounts);
  const findUserMenu = () => wrapper.findComponent(UserMenu);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SuperTopbar, {
      propsData: {
        sidebarData: mockSidebarData,
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

    describe('"Create new…" menu', () => {
      describe('when there are no menu items for it', () => {
        // This scenario usually happens for an "External" user.
        it('does not render it', () => {
          createComponent({ sidebarData: { ...mockSidebarData, create_new_menu_groups: [] } });
          expect(findCreateMenu().exists()).toBe(false);
        });
      });

      describe('when there are menu items for it', () => {
        it('passes the "Create new…" menu groups to the create-menu component', () => {
          expect(findCreateMenu().props('groups')).toBe(mockSidebarData.create_new_menu_groups);
        });
      });
    });

    it('renders BrandLogo component with correct props', () => {
      expect(findBrandLogo().props('logoUrl')).toBe(mockSidebarData.logo_url);
    });

    describe('GitLab Next badge', () => {
      describe('when on canary', () => {
        it('should render a badge to switch off GitLab Next', () => {
          createComponent({ sidebarData: { ...mockSidebarData, gitlab_com_and_canary: true } });
          expect(findNextBadge().text()).toBe('Next');
          expect(findNextBadge().attributes('href')).toBe(mockSidebarData.canary_toggle_com_url);
        });
      });

      describe('when not on canary', () => {
        it('should not render the GitLab Next badge', () => {
          createComponent({ sidebarData: { ...mockSidebarData, gitlab_com_and_canary: false } });
          expect(findNextBadge().exists()).toBe(false);
        });
      });
    });

    it('renders UserMenu when user is logged in', () => {
      expect(findUserMenu().props('data')).toEqual(mockSidebarData);
    });

    it('does not render UserMenu when user is not logged in', () => {
      createComponent({ sidebarData: { is_logged_in: false } });

      expect(findUserMenu().exists()).toBe(false);
    });

    it('renders UserCounts component when user is logged in', () => {
      expect(findUserCounts().props('sidebarData')).toEqual(mockSidebarData);
    });

    it('does not render UserCounts when user is not logged in', () => {
      createComponent({ sidebarData: { is_logged_in: false } });

      expect(findUserCounts().exists()).toBe(false);
    });
  });
});
