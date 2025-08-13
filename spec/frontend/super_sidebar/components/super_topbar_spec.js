import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuperTopbar from '~/super_sidebar/components/super_topbar.vue';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import OrganizationSwitcher from '~/super_sidebar/components/organization_switcher.vue';
import SearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import UserCounts from '~/super_sidebar/components/user_counts.vue';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { defaultOrganization as currentOrganization } from 'jest/organizations/mock_data';
import { sidebarData as mockSidebarData } from '../mock_data';

describe('SuperTopbar', () => {
  let wrapper;

  const OrganizationSwitcherStub = stubComponent(OrganizationSwitcher);
  const SearchModalStub = stubComponent(SearchModal);

  const findAdminLink = () => wrapper.findByTestId('topbar-admin-link');
  const findBrandLogo = () => wrapper.findComponent(BrandLogo);
  const findCreateMenu = () => wrapper.findComponent(CreateMenu);
  const findNextBadge = () => wrapper.findComponent(GlBadge);
  const findOrganizationSwitcher = () => wrapper.findComponent(OrganizationSwitcherStub);
  const findSearchButton = () => wrapper.findByTestId('super-topbar-search-button');
  const findSearchModal = () => wrapper.findComponent(SearchModal);
  const findStopImpersonationButton = () => wrapper.findByTestId('stop-impersonation-btn');
  const findUserCounts = () => wrapper.findComponent(UserCounts);
  const findUserMenu = () => wrapper.findComponent(UserMenu);

  const createComponent = (props = {}, provideOverrides = {}) => {
    wrapper = shallowMountExtended(SuperTopbar, {
      propsData: {
        sidebarData: mockSidebarData,
        ...props,
      },
      provide: {
        isImpersonating: false,
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

    describe('Organization switcher', () => {
      it('does not render the organization switcher', () => {
        expect(findOrganizationSwitcher().exists()).toBe(false);
      });

      describe('when `ui_for_organizations` feature flag is enabled, user is logged in and current organization is set', () => {
        beforeEach(async () => {
          window.gon.current_organization = currentOrganization;
          createComponent({ is_logged_in: true }, { glFeatures: { uiForOrganizations: true } });
          await waitForPromises();
        });

        it('renders the organization switcher', () => {
          expect(findOrganizationSwitcher().exists()).toBe(true);
        });
      });
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

    describe('Impersonate', () => {
      describe('when not impersonating another user', () => {
        it('does not render the "Stop impersonation" button', () => {
          createComponent({}, { isImpersonating: false });
          expect(findStopImpersonationButton().exists()).toBe(false);
        });
      });

      describe('when impersonating another user', () => {
        it('renders the "Stop impersonation" button', () => {
          createComponent({}, { isImpersonating: true });
          expect(findStopImpersonationButton().exists()).toBe(true);
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

    describe('Admin link', () => {
      describe('when user is admin', () => {
        it('renders', () => {
          createComponent({
            sidebarData: {
              ...mockSidebarData,
              admin_mode: { user_is_admin: true },
            },
          });
          expect(findAdminLink().attributes('href')).toBe(mockSidebarData.admin_url);
        });
      });

      describe('when user is not admin', () => {
        it('does not render', () => {
          createComponent();
          expect(findAdminLink().exists()).toBe(false);
        });
      });
    });
  });
});
