import { GlBadge } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Vue, { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import UserMenu from '~/super_sidebar/components/user_menu.vue';
import SearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import BrandLogo from 'jh_else_ce/super_sidebar/components/brand_logo.vue';
import MergeRequestMenu from '~/super_sidebar/components/merge_request_menu.vue';
import OrganizationSwitcher from '~/super_sidebar/components/organization_switcher.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import { userCounts } from '~/super_sidebar/user_counts_manager';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { stubComponent } from 'helpers/stub_component';
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
  const findIssuesCounter = () => wrapper.findByTestId('issues-shortcut-button');
  const findMRsCounter = () => wrapper.findByTestId('merge-requests-shortcut-button');
  const findTodosCounter = () => wrapper.findByTestId('todos-shortcut-button');
  const findMergeRequestMenu = () => wrapper.findComponent(MergeRequestMenu);
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
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      store,
      stubs: {
        OrganizationSwitcher: OrganizationSwitcherStub,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    describe('"Create new..." menu', () => {
      describe('when there are no menu items for it', () => {
        // This scenario usually happens for an "External" user.
        it('does not render it', () => {
          createWrapper({ sidebarData: { ...mockSidebarData, create_new_menu_groups: [] } });
          expect(findCreateMenu().exists()).toBe(false);
        });
      });

      describe('when there are menu items for it', () => {
        it('passes the "Create new..." menu groups to the create-menu component', () => {
          expect(findCreateMenu().props('groups')).toBe(mockSidebarData.create_new_menu_groups);
        });
      });
    });

    it('passes the "Merge request" menu groups to the merge_request_menu component', () => {
      expect(findMergeRequestMenu().props('items')).toBe(mockSidebarData.merge_request_menu);
    });

    it('renders issues counter', () => {
      const isuesCounter = findIssuesCounter();
      expect(isuesCounter.props('count')).toBe(userCounts.assigned_issues);
      expect(isuesCounter.props('href')).toBe(mockSidebarData.issues_dashboard_path);
      expect(isuesCounter.props('label')).toBe('Assigned issues');
      expect(isuesCounter.attributes('data-track-action')).toBe('click_link');
      expect(isuesCounter.attributes('data-track-label')).toBe('issues_link');
      expect(isuesCounter.attributes('data-track-property')).toBe('nav_core_menu');
      expect(isuesCounter.attributes('class')).toContain('dashboard-shortcuts-issues');
    });

    it('renders merge requests counter', () => {
      const mrsCounter = findMRsCounter();
      expect(mrsCounter.props('count')).toBe(
        userCounts.assigned_merge_requests + userCounts.review_requested_merge_requests,
      );
      expect(mrsCounter.props('label')).toBe('Merge requests');
      expect(mrsCounter.attributes('data-track-action')).toBe('click_dropdown');
      expect(mrsCounter.attributes('data-track-label')).toBe('merge_requests_menu');
      expect(mrsCounter.attributes('data-track-property')).toBe('nav_core_menu');
    });

    describe('Todos counter', () => {
      it('renders it', () => {
        const todosCounter = findTodosCounter();
        expect(todosCounter.props('href')).toBe(mockSidebarData.todos_dashboard_path);
        expect(todosCounter.props('label')).toBe('To-Do List');
        expect(todosCounter.attributes('data-track-action')).toBe('click_link');
        expect(todosCounter.attributes('data-track-label')).toBe('todos_link');
        expect(todosCounter.attributes('data-track-property')).toBe('nav_core_menu');
        expect(todosCounter.attributes('class')).toContain('shortcuts-todos');
      });

      it('should update todo counter when event with count is emitted', async () => {
        createWrapper();
        const count = 100;
        document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { count } }));
        await nextTick();
        expect(findTodosCounter().props('count')).toBe(count);
      });

      it('should update todo counter when event with diff is emitted', async () => {
        createWrapper();
        expect(findTodosCounter().props('count')).toBe(3);
        document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { delta: -2 } }));
        await nextTick();
        expect(findTodosCounter().props('count')).toBe(1);
      });
    });

    it('renders branding logo', () => {
      expect(findBrandLogo().exists()).toBe(true);
      expect(findBrandLogo().props('logoUrl')).toBe(mockSidebarData.logo_url);
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

  it('does not render merge request menu when merge_request_menu is null', () => {
    createWrapper({ sidebarData: { ...mockSidebarData, merge_request_menu: null } });

    expect(findMergeRequestMenu().exists()).toBe(false);
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

    it('search button should have tooltip', () => {
      const tooltip = getBinding(findSearchButton().element, 'gl-tooltip');
      expect(tooltip.value).toBe(`Type <kbd>/</kbd> to search`);
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

    describe('Search tooltip', () => {
      it('should hide search tooltip when modal is shown', async () => {
        findSearchModal().vm.$emit('shown');
        await nextTick();
        const tooltip = getBinding(findSearchButton().element, 'gl-tooltip');
        expect(tooltip.value).toBe('');
      });

      it('should add search tooltip when modal is hidden', async () => {
        findSearchModal().vm.$emit('hidden');
        await nextTick();
        const tooltip = getBinding(findSearchButton().element, 'gl-tooltip');
        expect(tooltip.value).toBe(`Type <kbd>/</kbd> to search`);
      });
    });

    describe('when feature flag is on', () => {
      beforeEach(() => {
        createWrapper({ provideOverrides: { glFeatures: { searchButtonTopRight: true } } });
      });

      it('should not render search button', () => {
        expect(findSearchButton().exists()).toBe(false);
      });

      it('should not render search modal', () => {
        expect(findSearchModal().exists()).toBe(false);
      });
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

    it('does not render counters', () => {
      expect(findIssuesCounter().exists()).toBe(false);
      expect(findMRsCounter().exists()).toBe(false);
      expect(findTodosCounter().exists()).toBe(false);
    });
  });

  describe('when `ui_for_organizations` feature flag is enabled', () => {
    describe('when logged in', () => {
      beforeEach(() => {
        isLoggedIn.mockReturnValue(true);
      });

      it('renders `OrganizationSwitcher component', async () => {
        createWrapper({ provideOverrides: { glFeatures: { uiForOrganizations: true } } });
        await waitForPromises();

        expect(findOrganizationSwitcher().exists()).toBe(true);
      });
    });

    describe('when not logged in', () => {
      beforeEach(() => {
        isLoggedIn.mockReturnValue(false);
      });

      it('does not render `OrganizationSwitcher component', async () => {
        createWrapper({ provideOverrides: { glFeatures: { uiForOrganizations: true } } });
        await waitForPromises();

        expect(findOrganizationSwitcher().exists()).toBe(false);
      });
    });
  });

  describe('when `ui_for_organizations` feature flag is disabled', () => {
    it('does not render `OrganizationSwitcher component', async () => {
      createWrapper();
      await waitForPromises();

      expect(findOrganizationSwitcher().exists()).toBe(false);
    });
  });
});
