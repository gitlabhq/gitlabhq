import { GlBadge } from '@gitlab/ui';
import Vuex from 'vuex';
import Vue, { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';
import CreateMenu from '~/super_sidebar/components/create_menu.vue';
import SearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';
import MergeRequestMenu from '~/super_sidebar/components/merge_request_menu.vue';
import Counter from '~/super_sidebar/components/counter.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import { userCounts } from '~/super_sidebar/user_counts_manager';
import { sidebarData } from '../mock_data';
import { MOCK_DEFAULT_SEARCH_OPTIONS } from './global_search/mock_data';

describe('UserBar component', () => {
  let wrapper;

  const findCreateMenu = () => wrapper.findComponent(CreateMenu);
  const findCounter = (at) => wrapper.findAllComponents(Counter).at(at);
  const findIssuesCounter = () => findCounter(0);
  const findMRsCounter = () => findCounter(1);
  const findTodosCounter = () => findCounter(2);
  const findMergeRequestMenu = () => wrapper.findComponent(MergeRequestMenu);
  const findBrandLogo = () => wrapper.findByTestId('brand-header-custom-logo');
  const findCollapseButton = () => wrapper.findByTestId('super-sidebar-collapse-button');
  const findSearchButton = () => wrapper.findByTestId('super-sidebar-search-button');
  const findSearchModal = () => wrapper.findComponent(SearchModal);
  const findStopImpersonationButton = () => wrapper.findByTestId('stop-impersonation-btn');

  Vue.use(Vuex);

  const store = new Vuex.Store({
    getters: {
      searchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
    },
  });
  const createWrapper = ({
    hasCollapseButton = true,
    extraSidebarData = {},
    provideOverrides = {},
  } = {}) => {
    wrapper = shallowMountExtended(UserBar, {
      propsData: {
        hasCollapseButton,
        sidebarData: { ...sidebarData, ...extraSidebarData },
      },
      provide: {
        rootPath: '/',
        toggleNewNavEndpoint: '/-/profile/preferences',
        isImpersonating: false,
        ...provideOverrides,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      store,
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('passes the "Create new..." menu groups to the create-menu component', () => {
      expect(findCreateMenu().props('groups')).toBe(sidebarData.create_new_menu_groups);
    });

    it('passes the "Merge request" menu groups to the merge_request_menu component', () => {
      expect(findMergeRequestMenu().props('items')).toBe(sidebarData.merge_request_menu);
    });

    it('renders issues counter', () => {
      const isuesCounter = findIssuesCounter();
      expect(isuesCounter.props('count')).toBe(userCounts.assigned_issues);
      expect(isuesCounter.props('href')).toBe(sidebarData.issues_dashboard_path);
      expect(isuesCounter.props('label')).toBe(__('Issues'));
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
      expect(mrsCounter.props('label')).toBe(__('Merge requests'));
      expect(mrsCounter.attributes('data-track-action')).toBe('click_dropdown');
      expect(mrsCounter.attributes('data-track-label')).toBe('merge_requests_menu');
      expect(mrsCounter.attributes('data-track-property')).toBe('nav_core_menu');
    });

    describe('Todos counter', () => {
      it('renders it', () => {
        const todosCounter = findTodosCounter();
        expect(todosCounter.props('href')).toBe('/dashboard/todos');
        expect(todosCounter.props('label')).toBe(__('To-Do list'));
        expect(todosCounter.attributes('data-track-action')).toBe('click_link');
        expect(todosCounter.attributes('data-track-label')).toBe('todos_link');
        expect(todosCounter.attributes('data-track-property')).toBe('nav_core_menu');
        expect(todosCounter.attributes('class')).toContain('shortcuts-todos');
      });

      it('should update todo counter when event is emitted', async () => {
        createWrapper();
        const count = 100;
        document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { count } }));
        await nextTick();
        expect(findTodosCounter().props('count')).toBe(count);
      });
    });

    it('renders branding logo', () => {
      expect(findBrandLogo().exists()).toBe(true);
      expect(findBrandLogo().attributes('src')).toBe(sidebarData.logo_url);
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
        createWrapper({ extraSidebarData: { gitlab_com_and_canary: true } });
        const badge = wrapper.findComponent(GlBadge);
        expect(badge.text()).toBe('Next');
        expect(badge.attributes('href')).toBe(sidebarData.canary_toggle_com_url);
      });
    });

    describe('when not on canary', () => {
      it('should not render the GitLab Next badge', () => {
        createWrapper({ extraSidebarData: { gitlab_com_and_canary: false } });
        const badge = wrapper.findComponent(GlBadge);
        expect(badge.exists()).toBe(false);
      });
    });
  });

  describe('Search', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('should render search button', () => {
      expect(findSearchButton().exists()).toBe(true);
    });

    it('search button should have tooltip', () => {
      const tooltip = getBinding(findSearchButton().element, 'gl-tooltip');
      expect(tooltip.value).toBe(`Search GitLab <kbd>/</kbd>`);
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
        expect(tooltip.value).toBe(`Search GitLab <kbd>/</kbd>`);
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
      const label = __('Stop impersonating');

      expect(btn.attributes('title')).toBe(label);
      expect(btn.attributes('aria-label')).toBe(label);
    });

    it('sets the href and data-method attributes', () => {
      const btn = findStopImpersonationButton();

      expect(btn.attributes('href')).toBe(sidebarData.stop_impersonation_path);
      expect(btn.attributes('data-method')).toBe('delete');
    });
  });
});
