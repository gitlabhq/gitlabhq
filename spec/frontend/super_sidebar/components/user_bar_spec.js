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
import { isLoggedIn } from '~/lib/utils/common_utils';
import { stubComponent } from 'helpers/stub_component';
import { defaultOrganization as currentOrganization } from 'jest/organizations/mock_data';
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

  describe('when `ui_for_organizations` feature flag is enabled, user is logged in and current organization is set', () => {
    beforeEach(async () => {
      window.gon.current_organization = currentOrganization;
      isLoggedIn.mockReturnValue(true);
      createWrapper({ provideOverrides: { glFeatures: { uiForOrganizations: true } } });
      await waitForPromises();
    });

    it('renders `OrganizationSwitcher component', () => {
      expect(findOrganizationSwitcher().exists()).toBe(true);
    });
  });

  describe.each`
    featureFlagEnabled | isLoggedInValue | currentOrganizationValue
    ${true}            | ${true}         | ${undefined}
    ${true}            | ${false}        | ${currentOrganization}
    ${true}            | ${false}        | ${undefined}
    ${false}           | ${true}         | ${currentOrganization}
    ${false}           | ${false}        | ${currentOrganization}
    ${false}           | ${false}        | ${undefined}
  `(
    'when `ui_for_organizations` feature flag is $featureFlagEnabled, isLoggedIn is $isLoggedInValue, and current organization is $currentOrganizationValue',
    ({ featureFlagEnabled, isLoggedInValue, currentOrganizationValue }) => {
      beforeEach(async () => {
        window.gon.current_organization = currentOrganizationValue;
        isLoggedIn.mockReturnValue(isLoggedInValue);
        createWrapper({
          provideOverrides: {
            glFeatures: {
              uiForOrganizations: featureFlagEnabled,
            },
          },
        });
        await waitForPromises();
      });

      it('does not render `OrganizationSwitcher component', () => {
        expect(findOrganizationSwitcher().exists()).toBe(false);
      });
    },
  );
});
