import { GlBadge } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Vue from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import SearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import OrganizationSwitcher from '~/super_sidebar/components/organization_switcher.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import UserCounts from '~/super_sidebar/components/user_counts.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { isLoggedIn as isLoggedInUtil } from '~/lib/utils/common_utils';
import { defaultOrganization as mockCurrentOrganization } from 'jest/organizations/mock_data';
import { sidebarData as mockSidebarData, loggedOutSidebarData } from '../mock_data';
import {
  MOCK_DEFAULT_SEARCH_OPTIONS,
  MOCK_SEARCH_QUERY,
  MOCK_SCOPED_SEARCH_OPTIONS,
} from './global_search/mock_data';

jest.mock('~/lib/utils/common_utils');

describe('UserBar component', () => {
  let wrapper;

  const OrganizationSwitcherStub = stubComponent(OrganizationSwitcher);

  const findCreateMenu = () => wrapper.findComponent(CreateMenu);
  const findUserMenu = () => wrapper.findComponent(UserMenu);
  const findUserCounts = () => wrapper.findComponent(UserCounts);
  const findBrandLogo = () => wrapper.findComponent(BrandLogo);
  const findCollapseButton = () => wrapper.findByTestId('super-sidebar-collapse-button');
  const findSearchButton = () => wrapper.findByTestId('super-sidebar-search-button');
  const findSearchModal = () => wrapper.findComponent(SearchModal);
  const findStopImpersonationButton = () => wrapper.findByTestId('stop-impersonation-btn');
  const findOrganizationSwitcher = () => wrapper.findComponent(OrganizationSwitcherStub);

  Vue.use(Vuex);

  const store = new Vuex.Store({
    state: {
      search: 'test',
      commandChar: '>',
    },
    getters: {
      searchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
      isCommandMode: () => true,
      searchQuery: () => MOCK_SEARCH_QUERY,
      scopedSearchOptions: () => MOCK_SCOPED_SEARCH_OPTIONS,
    },
  });
  const createWrapper = ({
    hasCollapseButton = true,
    sidebarData = mockSidebarData,
    provideOverrides = {},
  } = {}) => {
    wrapper = shallowMountExtended(UserBar, {
      propsData: {
        hasCollapseButton,
        sidebarData,
      },
      provide: {
        isImpersonating: false,
        ...provideOverrides,
      },
      store,
      stubs: {
        OrganizationSwitcher: OrganizationSwitcherStub,
      },
    });
  };

  afterEach(() => {
    window.gon = {};
  });

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    describe('"Create new…" menu', () => {
      describe('when there are no menu items for it', () => {
        // This scenario usually happens for an "External" user.
        it('does not render it', () => {
          createWrapper({ sidebarData: { ...mockSidebarData, create_new_menu_groups: [] } });
          expect(findCreateMenu().exists()).toBe(false);
        });
      });

      describe('when there are menu items for it', () => {
        it('passes the "Create new…" menu groups to the create-menu component', () => {
          expect(findCreateMenu().props('groups')).toBe(mockSidebarData.create_new_menu_groups);
        });
      });
    });

    it('renders branding logo', () => {
      expect(findBrandLogo().exists()).toBe(true);
      expect(findBrandLogo().props('logoUrl')).toBe(mockSidebarData.logo_url);
    });

    it('renders user counts component', () => {
      expect(findUserCounts().exists()).toBe(true);
      expect(findUserCounts().props('sidebarData')).toBe(mockSidebarData);
    });

    it('does not render the "Stop impersonating" button', () => {
      expect(findStopImpersonationButton().exists()).toBe(false);
    });

    it('renders collapse button when hasCollapseButton is true', () => {
      expect(findCollapseButton().exists()).toBe(true);
    });

    it('does not render collapse button when hasCollapseButton is false', () => {
      createWrapper({ hasCollapseButton: false });
      expect(findCollapseButton().exists()).toBe(false);
    });
  });

  describe('GitLab Next badge', () => {
    describe('when on canary', () => {
      it('should render a badge to switch off GitLab Next', () => {
        createWrapper({ sidebarData: { ...mockSidebarData, gitlab_com_and_canary: true } });
        const badge = wrapper.findComponent(GlBadge);
        expect(badge.text()).toBe('Next');
        expect(badge.attributes('href')).toBe(mockSidebarData.canary_toggle_com_url);
      });
    });

    describe('when not on canary', () => {
      it('should not render the GitLab Next badge', () => {
        createWrapper({ sidebarData: { ...mockSidebarData, gitlab_com_and_canary: false } });
        const badge = wrapper.findComponent(GlBadge);
        expect(badge.exists()).toBe(false);
      });
    });
  });

  describe('Search', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('should render search button', () => {
      expect(findSearchButton().exists()).toBe(true);
    });

    it('search button should have tracking', async () => {
      const { trackEventSpy } = bindInternalEventDocument(findSearchButton().element);
      await findSearchButton().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_search_button_to_activate_command_palette',
        {},
        undefined,
      );
    });

    it('should render search modal', () => {
      expect(findSearchModal().exists()).toBe(true);
    });
  });

  describe('While impersonating a user', () => {
    beforeEach(() => {
      createWrapper({ provideOverrides: { isImpersonating: true } });
    });

    it('renders the "Stop impersonating" button', () => {
      expect(findStopImpersonationButton().exists()).toBe(true);
    });

    it('sets the correct label on the button', () => {
      const btn = findStopImpersonationButton();
      const label = 'Stop impersonating';

      expect(btn.attributes('title')).toBe(label);
      expect(btn.attributes('aria-label')).toBe(label);
    });

    it('sets the href and data-method attributes', () => {
      const btn = findStopImpersonationButton();

      expect(btn.attributes('href')).toBe(mockSidebarData.stop_impersonation_path);
      expect(btn.attributes('data-method')).toBe('delete');
    });
  });

  describe('Logged out', () => {
    beforeEach(() => {
      createWrapper({ sidebarData: loggedOutSidebarData, gitlab_com_and_canary: true });
    });

    it('does not render brand logo', () => {
      expect(findBrandLogo().exists()).toBe(false);
    });

    it('does not render Next badge', () => {
      expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
    });

    it('does not render create menu', () => {
      expect(findCreateMenu().exists()).toBe(false);
    });

    it('does not render user menu', () => {
      expect(findUserMenu().exists()).toBe(false);
    });

    it('does not render user counts', () => {
      expect(findUserCounts().exists()).toBe(false);
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
          isLoggedInUtil.mockReturnValue(isLoggedIn);
          createWrapper({
            sidebarData: {
              ...mockSidebarData,
              has_multiple_organizations: hasMultipleOrganizations,
            },
            provideOverrides: {
              glFeatures: {
                uiForOrganizations: isFeatureFlagEnabled,
              },
            },
          });
          await waitForPromises();
        });

        it(`expects organization switcher existence to be ${expected}`, () => {
          expect(findOrganizationSwitcher().exists()).toBe(expected);
        });
      },
    );
  });
});
