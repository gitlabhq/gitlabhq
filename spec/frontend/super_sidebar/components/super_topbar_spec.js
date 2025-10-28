import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuperTopbar from '~/super_sidebar/components/super_topbar.vue';
import SuperSidebarToggle from '~/super_sidebar/components/super_sidebar_toggle.vue';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import OrganizationSwitcher from '~/super_sidebar/components/organization_switcher.vue';
import SearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import UserCounts from '~/super_sidebar/components/user_counts.vue';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import PromoMenu from '~/super_sidebar/components/promo_menu.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { defaultOrganization as mockCurrentOrganization } from 'jest/organizations/mock_data';
import { sidebarData as mockSidebarData } from '../mock_data';

describe('SuperTopbar', () => {
  let wrapper;

  const OrganizationSwitcherStub = stubComponent(OrganizationSwitcher);
  const SearchModalStub = stubComponent(SearchModal);

  const findSkipToLink = () => wrapper.findByTestId('super-topbar-skip-to');
  const findAdminLink = () => wrapper.findByTestId('topbar-admin-link');
  const findSigninButton = () => wrapper.findByTestId('topbar-signin-button');
  const findSignupButton = () => wrapper.findByTestId('topbar-signup-button');
  const findBrandLogo = () => wrapper.findComponent(BrandLogo);
  const findSidebarToggle = () => wrapper.findComponent(SuperSidebarToggle);
  const findCreateMenu = () => wrapper.findComponent(CreateMenu);
  const findNextBadge = () => wrapper.findComponent(GlBadge);
  const findOrganizationSwitcher = () => wrapper.findComponent(OrganizationSwitcherStub);
  const findSearchButton = () => wrapper.findByTestId('super-topbar-search-button');
  const findSearchModal = () => wrapper.findComponent(SearchModal);
  const findUserCounts = () => wrapper.findComponent(UserCounts);
  const findUserMenu = () => wrapper.findComponent(UserMenu);
  const findPromoMenu = () => wrapper.findComponent(PromoMenu);

  const createComponent = (props = {}, provideOverrides = {}) => {
    wrapper = shallowMountExtended(SuperTopbar, {
      propsData: {
        sidebarData: mockSidebarData,
        ...props,
      },
      provide: {
        isSaas: false,
        ...provideOverrides,
      },
      stubs: {
        OrganizationSwitcher: OrganizationSwitcherStub,
        SearchModal: SearchModalStub,
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

    it('renders skip to main content link when logged in', () => {
      expect(findSkipToLink().attributes('href')).toBe('#content-body');
    });

    describe('Mobile sidebar toggle', () => {
      it('has the correct class', () => {
        expect(findSidebarToggle().props('icon')).toBe('hamburger');
      });

      it('is not shown on large screens', () => {
        expect(findSidebarToggle().classes()).toContain('xl:gl-hidden');
      });

      it('is not shown when the sidebar has no menu items', () => {
        createComponent({
          sidebarData: { ...mockSidebarData, current_menu_items: [] },
        });
        expect(findSidebarToggle().exists()).toBe(false);
      });
    });

    describe('Organization switcher', () => {
      describe.each`
        isFeatureFlagEnabled | isLoggedIn | currentOrganization        | hasMultipleOrganizations | expected
        ${false}             | ${false}   | ${undefined}               | ${false}                 | ${false}
        ${false}             | ${false}   | ${undefined}               | ${true}                  | ${false}
        ${false}             | ${false}   | ${mockCurrentOrganization} | ${false}                 | ${false}
        ${false}             | ${false}   | ${mockCurrentOrganization} | ${true}                  | ${false}
        ${false}             | ${true}    | ${undefined}               | ${false}                 | ${false}
        ${false}             | ${true}    | ${undefined}               | ${true}                  | ${false}
        ${false}             | ${true}    | ${mockCurrentOrganization} | ${false}                 | ${false}
        ${false}             | ${true}    | ${mockCurrentOrganization} | ${true}                  | ${false}
        ${true}              | ${false}   | ${undefined}               | ${false}                 | ${false}
        ${true}              | ${false}   | ${undefined}               | ${true}                  | ${false}
        ${true}              | ${false}   | ${mockCurrentOrganization} | ${false}                 | ${false}
        ${true}              | ${false}   | ${mockCurrentOrganization} | ${true}                  | ${false}
        ${true}              | ${true}    | ${undefined}               | ${false}                 | ${false}
        ${true}              | ${true}    | ${undefined}               | ${true}                  | ${false}
        ${true}              | ${true}    | ${mockCurrentOrganization} | ${false}                 | ${false}
        ${true}              | ${true}    | ${mockCurrentOrganization} | ${true}                  | ${true}
      `(
        'when `ui_for_organizations` feature flag is $isFeatureFlagEnabled, logged in state is $isLoggedIn, current organization $currentOrganization, and has_multiple_organizations is $hasMultipleOrganizations',
        ({
          isFeatureFlagEnabled,
          isLoggedIn,
          currentOrganization,
          hasMultipleOrganizations,
          expected,
        }) => {
          beforeEach(async () => {
            window.gon.current_organization = currentOrganization;
            createComponent(
              {
                sidebarData: {
                  ...mockSidebarData,
                  is_logged_in: isLoggedIn,
                  has_multiple_organizations: hasMultipleOrganizations,
                },
              },
              { glFeatures: { uiForOrganizations: isFeatureFlagEnabled } },
            );
            await waitForPromises();
          });

          it(`expects organization switcher existence to be ${expected}`, () => {
            expect(findOrganizationSwitcher().exists()).toBe(expected);
          });
        },
      );
    });

    describe('Search', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('should render search button', () => {
        expect(findSearchButton().exists()).toBe(true);
      });

      it('should render search modal', () => {
        expect(findSearchModal().exists()).toBe(true);
      });
    });

    describe('"Create new…" menu', () => {
      describe('when there are no menu items for it', () => {
        // This scenario usually happens for an "External" user.
        it('does not render it', () => {
          createComponent({
            sidebarData: { ...mockSidebarData, is_logged_in: true, create_new_menu_groups: [] },
          });
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
      createComponent({ sidebarData: { ...mockSidebarData, is_logged_in: false } });

      expect(findUserMenu().exists()).toBe(false);
    });

    it('renders UserCounts component when user is logged in', () => {
      expect(findUserCounts().props('sidebarData')).toEqual(mockSidebarData);
    });

    it('does not render UserCounts when user is not logged in', () => {
      createComponent({ sidebarData: { ...mockSidebarData, is_logged_in: false } });

      expect(findUserCounts().exists()).toBe(false);
    });

    describe('Admin link', () => {
      describe('when user is admin and admin mode feature is not enabled', () => {
        it('renders', () => {
          createComponent({
            sidebarData: {
              ...mockSidebarData,
              admin_mode: { user_is_admin: true, admin_mode_feature_enabled: false },
            },
          });
          expect(findAdminLink().attributes('href')).toBe(mockSidebarData.admin_url);
        });
      });

      describe('when user is admin and admin mode is active', () => {
        it('renders', () => {
          createComponent({
            sidebarData: {
              ...mockSidebarData,
              admin_mode: {
                user_is_admin: true,
                admin_mode_feature_enabled: true,
                admin_mode_active: true,
              },
            },
          });
          expect(findAdminLink().attributes('href')).toBe(mockSidebarData.admin_url);
        });
      });

      describe('when user is admin but admin mode feature is enabled and not active', () => {
        it('does not render', () => {
          createComponent({
            sidebarData: {
              ...mockSidebarData,
              admin_mode: {
                user_is_admin: true,
                admin_mode_feature_enabled: true,
                admin_mode_active: false,
              },
            },
          });
          expect(findAdminLink().exists()).toBe(false);
        });
      });

      describe('when user is not admin', () => {
        it('does not render', () => {
          createComponent();
          expect(findAdminLink().exists()).toBe(false);
        });
      });
    });

    describe('Promo menu', () => {
      it('renders when user is logged out', () => {
        createComponent({
          sidebarData: {
            ...mockSidebarData,
            is_logged_in: false,
          },
        });

        expect(findPromoMenu().exists()).toBe(true);
      });

      it('does not render when user is logged in', () => {
        createComponent();

        expect(findPromoMenu().exists()).toBe(false);
      });
    });

    describe('Signin button', () => {
      describe('when user is logged out', () => {
        it('does not render when signin is not visible', () => {
          createComponent({
            sidebarData: {
              ...mockSidebarData,
              is_logged_in: false,
              sign_in_visible: false,
            },
          });
          expect(findSigninButton().exists()).toBe(false);
        });

        it('renders', () => {
          createComponent({
            sidebarData: {
              ...mockSidebarData,
              is_logged_in: false,
            },
          });
          expect(findSigninButton().attributes('href')).toBe(mockSidebarData.sign_in_path);
        });
      });

      describe('when user is logged in', () => {
        it('does not render', () => {
          createComponent();
          expect(findSigninButton().exists()).toBe(false);
        });
      });
    });

    describe('Signup button', () => {
      describe('when user is logged out', () => {
        it('does not render when signup is not allowed', () => {
          createComponent({
            sidebarData: {
              ...mockSidebarData,
              is_logged_in: false,
              allow_signup: false,
            },
          });
          expect(findSignupButton().exists()).toBe(false);
        });

        it('renders register when not in SaaS mode', () => {
          createComponent({
            sidebarData: {
              ...mockSidebarData,
              is_logged_in: false,
            },
          });
          expect(findSignupButton().text()).toBe('Register');
          expect(findSignupButton().attributes('href')).toBe(
            mockSidebarData.new_user_registration_path,
          );
        });

        it('renders free trial when in Saas Mode', () => {
          createComponent(
            {
              sidebarData: {
                ...mockSidebarData,
                is_logged_in: false,
              },
            },
            { isSaas: true },
          );
          expect(findSignupButton().text()).toBe('Get free trial');
          expect(findSignupButton().attributes('href')).toBe(
            mockSidebarData.new_user_registration_path,
          );
        });
      });

      describe('when user is logged in', () => {
        it('does not render', () => {
          createComponent();
          expect(findSignupButton().exists()).toBe(false);
        });
      });
    });
  });
});
