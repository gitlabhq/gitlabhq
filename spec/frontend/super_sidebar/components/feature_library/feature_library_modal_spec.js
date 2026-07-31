import MockAdapter from 'axios-mock-adapter';
import { GlModal, GlSearchBoxByType, GlCollapse, GlEmptyState, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_TOO_MANY_REQUESTS,
} from '~/lib/utils/http_status';
import ScrollScrim from '~/super_sidebar/components/scroll_scrim.vue';
import FeatureLibraryModal from '~/super_sidebar/components/feature_library/feature_library_modal.vue';
import FeatureLibraryItem from '~/super_sidebar/components/feature_library/feature_library_item.vue';
import {
  EVENT_OPEN_FEATURE_LIBRARY_MODAL,
  EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL,
  EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
} from '~/super_sidebar/tracking_constants';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));
jest.mock('~/lib/utils/path_helpers/feature_library', () => ({
  onboardingFeatureLibrarySearchPath: () => '/-/onboarding/feature_library/search',
}));

const SEARCH_URL = '/-/onboarding/feature_library/search';

// Mirrors the nav tree shape passed down from sidebar_menu.vue: sections (menu
// groups) holding leaf nav items enriched with feature-library metadata.
const defaultSections = [
  {
    id: 'plan_menu',
    title: 'Plan',
    items: [
      {
        id: 'project_issue_list',
        title: 'Work items',
        description: 'Track tasks and issues',
        library_icon: 'issues',
      },
      {
        id: 'boards',
        title: 'Boards',
        description: 'Visualize work with boards',
        library_icon: 'list-numbered',
        link: '/group/project/-/boards',
      },
      {
        id: 'milestones',
        title: 'Milestones',
        description: 'Manage project milestones',
        library_icon: 'milestone',
      },
    ],
  },
  {
    id: 'code_menu',
    title: 'Code',
    items: [
      {
        id: 'repository',
        title: 'Repository',
        description: 'Browse and manage your code',
        library_icon: 'code',
        tier: 'free',
      },
    ],
  },
  {
    id: 'manage_menu',
    title: 'Manage',
    items: [
      {
        id: 'members',
        title: 'Members',
        description: 'Manage project members',
        library_icon: 'users',
        link: '/group/project/-/project_members',
      },
    ],
  },
  {
    id: 'settings_menu',
    title: 'Settings',
    items: [
      {
        id: 'general_settings',
        title: 'General',
      },
    ],
  },
];

describe('FeatureLibraryModal', () => {
  let wrapper;
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  const focusInput = jest.fn();
  const hideModal = jest.fn();

  const createWrapper = ({
    currentPinnedIds = [],
    panelType = 'project',
    showFeedbackLink = false,
    sections = defaultSections,
    supportsPins,
  } = {}) => {
    wrapper = shallowMountExtended(FeatureLibraryModal, {
      propsData: { sections, currentPinnedIds, showFeedbackLink, supportsPins },
      provide: { panelType },
      // Stub GlModal (declared props stay props, everything else surfaces as
      // attrs) and render all its slots so footer/body content is inspectable.
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
          methods: { hide: hideModal },
        }),
        GlSearchBoxByType: stubComponent(GlSearchBoxByType, { methods: { focusInput } }),
        // Render collapse slot content so grouped items are inspectable.
        GlCollapse: stubComponent(GlCollapse, {
          template: '<div v-if="visible"><slot></slot></div>',
          props: ['visible'],
        }),
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findSectionToggles = () =>
    wrapper.findAllComponentsByTestId('feature-library-section-toggle');
  const findSectionTitles = () => findSectionToggles().wrappers.map((w) => w.text());
  const findCollapses = () => wrapper.findAllComponents(GlCollapse);
  const findItems = () => wrapper.findAllComponents(FeatureLibraryItem);
  const findItemIds = () => findItems().wrappers.map((w) => w.props('item').id);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findByTestId('search-loading');
  const findScrollArea = () => wrapper.findByTestId('feature-library-scroll-area');
  const findGrid = () => wrapper.findByTestId('feature-library-grid');
  const findSectionGrid = () => wrapper.findByTestId('feature-library-section-grid');
  const findFeedbackLink = () => wrapper.findComponent(GlLink);

  const emitSearch = async (query) => {
    await findSearch().vm.$emit('input', query);
  };

  describe('rendering', () => {
    beforeEach(() => createWrapper());

    it('renders one section heading per section that has enriched items', () => {
      expect(findSectionTitles()).toEqual(['Plan', 'Code', 'Manage']);
    });

    it('excludes settings menus', () => {
      expect(findSectionTitles()).not.toContain('Settings');
    });

    it('wraps content in a scroll-scrim area so overflow fades at the edges', () => {
      expect(findScrollArea().exists()).toBe(true);
      expect(wrapper.findComponent(ScrollScrim).exists()).toBe(true);
    });

    it('renders a search input', () => {
      expect(findSearch().exists()).toBe(true);
    });

    it.each([
      ['project', 'Search features in this project'],
      ['group', 'Search features in this group'],
      ['your_work', 'Search GitLab features'],
    ])('uses a %s-specific search placeholder', (panelType, expected) => {
      createWrapper({ panelType });
      expect(findSearch().attributes('placeholder')).toBe(expected);
    });

    it('debounces search input using the shared default interval', () => {
      expect(Number(findSearch().attributes('debounce'))).toBe(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    });

    it('does not show a loading indicator by default', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('hidden nav items', () => {
    beforeEach(() => {
      createWrapper({
        sections: [
          {
            id: 'plan_menu',
            title: 'Plan',
            items: [
              {
                id: 'issue_list',
                title: 'Work items',
                description: 'Plan, track, and manage work in one place',
                library_icon: 'work-items',
              },
              {
                id: 'group_epic_list',
                title: 'Work items',
                description: 'Break down large initiatives into smaller, manageable work items',
                library_icon: 'epic',
                tier: 'premium',
                link_classes: 'js-super-sidebar-nav-item-hidden',
              },
            ],
          },
        ],
      });
    });

    it('excludes items hidden in the super sidebar (js-super-sidebar-nav-item-hidden)', () => {
      expect(findItemIds()).toEqual(['issue_list']);
    });
  });

  describe('modal layout', () => {
    describe('with default props', () => {
      beforeEach(() => createWrapper());

      it('does not use centered so the top edge stays anchored during search', () => {
        expect(findModal().attributes('centered')).toBeUndefined();
      });

      it('caps its height so tall content scrolls internally', () => {
        expect(findModal().attributes('scrollable')).toBeDefined();
      });

      it('applies the feature-library-modal class for top-anchored positioning', () => {
        expect(findModal().props('modalClass')).toContain('feature-library-modal');
      });

      describe('footer visibility', () => {
        describe('when the feedback link is enabled', () => {
          beforeEach(() => createWrapper({ showFeedbackLink: true }));

          it('shows the footer', () => {
            expect(findModal().attributes('hide-footer')).toBeUndefined();
          });
        });

        describe('when there is no feedback link to show', () => {
          beforeEach(() => createWrapper({ showFeedbackLink: false }));

          it('hides the footer', () => {
            expect(findModal().attributes('hide-footer')).toBe('true');
          });
        });
      });
    });
  });

  describe('catalog', () => {
    beforeEach(() => createWrapper());

    it('lists nav items', () => {
      const ids = findItems().wrappers.map((w) => w.props('item').id);
      expect(ids.sort()).toEqual([
        'boards',
        'members',
        'milestones',
        'project_issue_list',
        'repository',
      ]);
    });

    it('maps library_icon onto the item icon', () => {
      const repository = findItems().wrappers.find((w) => w.props('item').id === 'repository');
      expect(repository.props('item').icon).toBe('code');
    });

    it('tags each item with the id of its parent section as its category', () => {
      const items = findItems().wrappers.map((w) => w.props('item'));
      expect(items.filter((i) => i.category === 'plan_menu').map((i) => i.id)).toEqual([
        'project_issue_list',
        'boards',
        'milestones',
      ]);
      expect(items.filter((i) => i.category === 'code_menu').map((i) => i.id)).toEqual([
        'repository',
      ]);
    });
  });

  describe('grouping when browsing', () => {
    beforeEach(() => createWrapper());

    it('groups items into a section per category, each under its own heading', () => {
      expect(findSectionTitles()).toEqual(['Plan', 'Code', 'Manage']);
    });

    it('renders each group as a collapsible section, expanded by default', () => {
      const collapses = findCollapses();
      expect(collapses).toHaveLength(3);
      collapses.wrappers.forEach((collapse) => {
        expect(collapse.props('visible')).toBe(true);
      });
    });

    it('collapses a section when its toggle is clicked', async () => {
      await findSectionToggles().at(0).vm.$emit('click');

      expect(findCollapses().at(0).props('visible')).toBe(false);
      // Other sections stay expanded.
      expect(findCollapses().at(1).props('visible')).toBe(true);
    });

    it('re-expands a collapsed section when its toggle is clicked again', async () => {
      await findSectionToggles().at(0).vm.$emit('click');
      await findSectionToggles().at(0).vm.$emit('click');

      expect(findCollapses().at(0).props('visible')).toBe(true);
    });

    it('renders each section’s items in order, grouped under its heading', () => {
      // Sections render in catalog order (Plan, then Code), so the flattened
      // item order reflects the per-section grouping.
      expect(findItemIds()).toEqual([
        'project_issue_list',
        'boards',
        'milestones',
        'repository',
        'members',
      ]);
    });

    it('wires each toggle to its collapse via aria-controls and a matching id', () => {
      const toggle = findSectionToggles().at(0);
      const collapse = findCollapses().at(0);
      const controls = toggle.attributes('aria-controls');

      expect(controls).toBe('feature-library-section-plan_menu');
      expect(collapse.attributes('id')).toBe(controls);
    });
  });

  describe('feature discovery search', () => {
    describe('title/description matching (client-side, instant)', () => {
      beforeEach(() => createWrapper());

      it('hides results and shows a loading indicator while the endpoint is in flight', async () => {
        mockAxios.onGet(SEARCH_URL).reply(() => new Promise(() => {}));
        await emitSearch('repo');

        expect(findGrid().exists()).toBe(false);
        expect(findLoadingIcon().exists()).toBe(true);
      });

      it('shows all results together once the endpoint resolves', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['boards'] });
        await emitSearch('repo');
        await waitForPromises();

        expect(findGrid().exists()).toBe(true);
        expect(findItemIds()).toContain('repository');
        expect(findItemIds()).toContain('boards');
      });

      it('renders results as one flat, ungrouped list rather than collapsible sections', async () => {
        // Search deliberately drops the category grouping: matches are ranked
        // across the whole catalog, so section headings would be noise.
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['boards'] });
        await emitSearch('repo');
        await waitForPromises();

        expect(findGrid().exists()).toBe(true);
        expect(findSectionGrid().exists()).toBe(false);
        expect(findSectionToggles()).toHaveLength(0);
        expect(findCollapses()).toHaveLength(0);
      });

      it('hides the loading indicator once the endpoint resolves', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        await emitSearch('repo');
        expect(findLoadingIcon().exists()).toBe(true);

        await waitForPromises();
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('synonym matches appear first (backend-ranked), direct matches follow', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['boards', 'repository'] });
        await emitSearch('repo');
        await waitForPromises();

        expect(findItemIds()[0]).toBe('boards');
        expect(findItemIds()[1]).toBe('repository');
      });

      it('does not duplicate items that match both title and endpoint', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['repository'] });
        await emitSearch('repo');
        await waitForPromises();

        expect(findItemIds().filter((id) => id === 'repository')).toHaveLength(1);
      });

      it('works on non-endpoint panels (e.g. organization) via title/description only', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        createWrapper({ panelType: 'organization' });
        await emitSearch('repo');
        await waitForPromises();

        expect(findItemIds()).toEqual(['repository']);
      });
    });

    describe('endpoint synonym matching', () => {
      beforeEach(() => createWrapper());

      it('does not call the endpoint for queries shorter than 2 characters', async () => {
        await emitSearch('r');
        await waitForPromises();

        expect(mockAxios.history.get).toHaveLength(0);
      });

      it('sends the trimmed query and panel type as request params', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        await emitSearch('  repo  ');
        await waitForPromises();

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0].params).toEqual({ query: 'repo', panel: 'project' });
      });

      it('appends synonym-only results after title matches resolve', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['boards'] });
        await emitSearch('sprint');
        await waitForPromises();

        expect(findItemIds()).toContain('boards');
      });

      it('preserves endpoint ranking order among synonym-only results', async () => {
        mockAxios
          .onGet(SEARCH_URL)
          .reply(HTTP_STATUS_OK, { ids: ['boards', 'project_issue_list'] });
        await emitSearch('sprint');
        await waitForPromises();

        expect(findItemIds()).toEqual(['boards', 'project_issue_list']);
      });

      it('silently drops endpoint ids that have no catalog entry', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['nonexistent_id', 'boards'] });
        await emitSearch('sprint');
        await waitForPromises();

        expect(findItemIds()).not.toContain('nonexistent_id');
        expect(findItemIds()).toContain('boards');
      });

      it('treats a response with no ids field as no synonym matches', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, {});
        await emitSearch('repo');
        await waitForPromises();

        expect(findItemIds()).toEqual(['repository']);
      });

      it('on rate limit (429), falls back to title-only without reporting to Sentry', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_TOO_MANY_REQUESTS);
        await emitSearch('repo');
        await waitForPromises();

        expect(Sentry.captureException).not.toHaveBeenCalled();
        expect(findItemIds()).toEqual(['repository']);
      });

      it('on error, reports to Sentry and falls back to title-only results', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await emitSearch('repo');
        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error), {
          tags: { feature_category: 'onboarding' },
        });
        expect(findItemIds()).toEqual(['repository']);
      });

      describe('stale state guard', () => {
        it('clears previous endpoint results immediately when a new query starts', async () => {
          mockAxios
            .onGet(SEARCH_URL)
            .replyOnce(HTTP_STATUS_OK, { ids: ['boards'] })
            .onGet(SEARCH_URL)
            .replyOnce(() => new Promise(() => {}));

          await emitSearch('sprint');
          await waitForPromises();

          expect(findItemIds()).toContain('boards');

          await emitSearch('repo');

          expect(findGrid().exists()).toBe(false);
          expect(findLoadingIcon().exists()).toBe(true);
        });
      });

      describe('stale response guard', () => {
        it('ignores endpoint results from a superseded query', async () => {
          let resolveFirst;
          mockAxios
            .onGet(SEARCH_URL)
            .replyOnce(
              () =>
                new Promise((resolve) => {
                  resolveFirst = resolve;
                }),
            )
            .onGet(SEARCH_URL)
            .replyOnce(HTTP_STATUS_OK, { ids: ['boards'] });

          await emitSearch('wo');
          await emitSearch('repository');
          await waitForPromises();

          resolveFirst([HTTP_STATUS_OK, { ids: ['project_issue_list'] }]);
          await waitForPromises();

          expect(findItemIds()).not.toContain('project_issue_list');
        });
      });
    });

    describe('empty state', () => {
      beforeEach(() => createWrapper());

      it('shows empty state when neither title nor endpoint matches anything', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        await emitSearch('zzznomatch');
        await waitForPromises();

        expect(findItems()).toHaveLength(0);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('does not show empty state while the endpoint is still in flight (title results visible)', async () => {
        mockAxios.onGet(SEARCH_URL).reply(() => new Promise(() => {}));
        await emitSearch('repo');

        expect(findEmptyState().exists()).toBe(false);
      });

      it('does not show empty state when query is less than 2 characters', async () => {
        await emitSearch('r');
        expect(findEmptyState().exists()).toBe(false);
      });

      it('uses the generic no-results title', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        await emitSearch('zzznomatch');
        await waitForPromises();

        expect(findEmptyState().props('title')).toBe('No features match your search');
      });
    });

    describe('clearing search', () => {
      beforeEach(() => createWrapper());

      it('hides the loading indicator when the box is cleared mid-flight', async () => {
        mockAxios.onGet(SEARCH_URL).reply(() => new Promise(() => {}));
        await emitSearch('repo');
        expect(findLoadingIcon().exists()).toBe(true);

        await emitSearch('');
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('restores the full catalog when the query is cleared', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['repository'] });
        await emitSearch('repo');
        await waitForPromises();

        await emitSearch('');
        await waitForPromises();

        expect(findItemIds().sort()).toEqual([
          'boards',
          'members',
          'milestones',
          'project_issue_list',
          'repository',
        ]);
      });
    });

    describe('on modal hide', () => {
      beforeEach(() => createWrapper());

      it('resets search and endpoint state so reopening shows the full catalog', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['boards'] });
        await emitSearch('sprint');
        await waitForPromises();

        findModal().vm.$emit('hidden');
        await nextTick();

        expect(findSearch().props('value')).toBe('');
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findItemIds().sort()).toEqual([
          'boards',
          'members',
          'milestones',
          'project_issue_list',
          'repository',
        ]);
      });

      it('re-expands any collapsed sections so reopening shows them expanded', async () => {
        await findSectionToggles().at(0).vm.$emit('click');
        expect(findCollapses().at(0).props('visible')).toBe(false);

        findModal().vm.$emit('hidden');
        await nextTick();

        findCollapses().wrappers.forEach((collapse) => {
          expect(collapse.props('visible')).toBe(true);
        });
      });
    });
  });

  describe('progressive reveal', () => {
    const largeSections = [
      {
        id: 'plan_menu',
        title: 'Plan',
        items: Array.from({ length: 25 }, (_, i) => ({
          id: `plan_item_${i}`,
          title: `Plan item ${i}`,
          description: `Description ${i}`,
          library_icon: 'issues',
        })),
      },
      {
        id: 'code_menu',
        title: 'Code',
        items: Array.from({ length: 15 }, (_, i) => ({
          id: `code_item_${i}`,
          title: `Code item ${i}`,
          description: `Description ${i}`,
          library_icon: 'code',
        })),
      },
    ];

    beforeEach(() => {
      jest.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => {
        cb();
        return 1;
      });
      createWrapper({ sections: largeSections });
    });

    it('only mounts the first chunk of the catalog synchronously', () => {
      expect(findItems()).toHaveLength(18);
    });

    it('reveals the full catalog after the modal is shown', async () => {
      findModal().vm.$emit('shown');
      await nextTick();
      expect(findItems()).toHaveLength(40);
    });

    it('resets to the first chunk when the modal is hidden, so reopening stays fast', async () => {
      findModal().vm.$emit('shown');
      await nextTick();
      findModal().vm.$emit('hidden');
      await nextTick();
      expect(findItems()).toHaveLength(18);
    });

    it('shows all search matches even before the reveal has run', async () => {
      mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
      await emitSearch('Plan item');
      await waitForPromises();
      expect(findItems()).toHaveLength(25);
    });

    it('renders every section heading even when the first section exceeds the reveal budget', () => {
      // The first section (25 items) alone exceeds the initial 18-item budget,
      // but both section headings must still be present so collapsing the
      // first section immediately surfaces the second.
      expect(findSectionTitles()).toEqual(['Plan', 'Code']);
    });
  });

  describe('keyboard-first navigation', () => {
    const pressEnter = () =>
      findSearch().vm.$emit('keydown', new KeyboardEvent('keydown', { key: 'Enter' }));

    describe('when the modal is shown', () => {
      beforeEach(() => {
        createWrapper();
        findModal().vm.$emit('shown');
      });

      it('focuses the search box', () => {
        expect(focusInput).toHaveBeenCalled();
      });
    });

    describe('when a query has results', () => {
      beforeEach(async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        createWrapper();
        await emitSearch('board');
        await waitForPromises();
      });

      it('navigates to the first displayed result on Enter', () => {
        pressEnter();

        expect(visitUrl).toHaveBeenCalledWith('/group/project/-/boards');
      });

      it('closes the modal before navigating on Enter', () => {
        pressEnter();

        expect(hideModal).toHaveBeenCalled();
      });
    });

    describe('when the modal is closed and reopened with a stale query', () => {
      beforeEach(async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        createWrapper();
        await emitSearch('board');
        await waitForPromises();

        findModal().vm.$emit('hidden');
        findModal().vm.$emit('shown');
      });

      it('does not navigate on Enter', () => {
        pressEnter();

        expect(visitUrl).not.toHaveBeenCalled();
      });
    });

    describe('when synonym matches exist', () => {
      beforeEach(async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['members'] });
        createWrapper();
        await emitSearch('sprint');
        await waitForPromises();
      });

      it('navigates to the backend-ranked first result on Enter', () => {
        pressEnter();

        expect(visitUrl).toHaveBeenCalledWith('/group/project/-/project_members');
      });
    });

    describe('when the query is empty', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('does nothing on Enter', () => {
        pressEnter();

        expect(visitUrl).not.toHaveBeenCalled();
      });
    });

    describe('while the search endpoint is in flight', () => {
      beforeEach(async () => {
        mockAxios.onGet(SEARCH_URL).reply(() => new Promise(() => {}));
        createWrapper();
        await emitSearch('board');
      });

      it('does nothing on Enter', () => {
        pressEnter();

        expect(visitUrl).not.toHaveBeenCalled();
      });
    });

    describe('when the first result has no link', () => {
      beforeEach(async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        createWrapper();
        await emitSearch('milestones');
        await waitForPromises();
      });

      it('does nothing on Enter', () => {
        pressEnter();

        expect(visitUrl).not.toHaveBeenCalled();
      });
    });

    describe('when there are no results', () => {
      beforeEach(async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        createWrapper();
        await emitSearch('nonexistent feature');
        await waitForPromises();
      });

      it('does nothing on Enter', () => {
        pressEnter();

        expect(visitUrl).not.toHaveBeenCalled();
      });
    });
  });

  describe('pin toggle', () => {
    beforeEach(() => createWrapper());

    it('re-emits pin-toggle (with title) from grid items', () => {
      findItems().at(0).vm.$emit('pin-toggle', 'some_id', true, 'Some title');
      expect(wrapper.emitted('pin-toggle')).toEqual([['some_id', true, 'Some title']]);
    });
  });

  describe('currentPinnedIds', () => {
    beforeEach(() => createWrapper({ currentPinnedIds: ['repository'] }));

    it('passes pinned=true to items whose id is in currentPinnedIds', () => {
      const matchingItem = findItems().wrappers.find((w) => w.props('item').id === 'repository');
      expect(matchingItem.props('pinned')).toBe(true);
    });
  });

  describe('supportsPins', () => {
    it('defaults to not supporting pins', () => {
      createWrapper();
      expect(findItems().at(0).props('supportsPins')).toBe(false);
    });

    describe('when pins are supported', () => {
      beforeEach(() => createWrapper({ supportsPins: true }));

      it('forwards supportsPins to every grid item', () => {
        expect(findItems().wrappers.every((w) => w.props('supportsPins') === true)).toBe(true);
      });
    });

    describe('when pins are not supported', () => {
      beforeEach(() => createWrapper({ supportsPins: false }));

      it('forwards supportsPins to every grid item', () => {
        expect(findItems().wrappers.every((w) => w.props('supportsPins') === false)).toBe(true);
      });
    });
  });

  describe('internal events tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    // The mixin forwards a third `category` arg (undefined) to InternalEvents.trackEvent.
    const CATEGORY = undefined;

    beforeEach(() => {
      createWrapper();
    });

    it('tracks opening the modal when it is shown', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findModal().vm.$emit('shown');
      expect(trackEventSpy).toHaveBeenCalledWith(EVENT_OPEN_FEATURE_LIBRARY_MODAL, {}, CATEGORY);
    });

    it('tracks pinning an item, labelled with the item id', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findItems().at(0).vm.$emit('pin-toggle', 'repository', true, 'Repository');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
        { label: 'repository' },
        CATEGORY,
      );
    });

    it('tracks unpinning an item, labelled with the item id', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findItems().at(0).vm.$emit('pin-toggle', 'repository', false, 'Repository');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
        { label: 'repository' },
        CATEGORY,
      );
    });

    it('tracks navigating to a feature, labelled with the item id', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findItems().at(0).vm.$emit('navigate', 'repository');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
        { label: 'repository' },
        CATEGORY,
      );
    });

    it('tracks navigating via Enter in the search box, labelled with the item id', async () => {
      mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
      await emitSearch('board');
      await waitForPromises();

      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findSearch().vm.$emit('keydown', new KeyboardEvent('keydown', { key: 'Enter' }));

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
        { label: 'boards' },
        CATEGORY,
      );
    });

    it('tracks a search event when the user types a query', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findSearch().vm.$emit('input', 'repo');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL,
        {},
        CATEGORY,
      );
    });

    it('does not track a search event when the query is blank', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findSearch().vm.$emit('input', '   ');
      expect(trackEventSpy).not.toHaveBeenCalled();
    });

    it('tracks a search event exactly once per input', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findSearch().vm.$emit('input', 'repo');
      expect(trackEventSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('feedback link', () => {
    describe('when showFeedbackLink is true', () => {
      beforeEach(() => createWrapper({ showFeedbackLink: true }));

      it('renders the feedback link', () => {
        expect(findFeedbackLink().exists()).toBe(true);
      });

      it('points the feedback link at the feedback issue', () => {
        expect(findFeedbackLink().attributes('href')).toBe(
          'https://gitlab.com/gitlab-org/gitlab/-/work_items/604008',
        );
      });
    });

    describe('when showFeedbackLink is false', () => {
      beforeEach(() => createWrapper({ showFeedbackLink: false }));

      it('does not render the feedback link', () => {
        expect(findFeedbackLink().exists()).toBe(false);
      });
    });

    describe('by default', () => {
      beforeEach(() => createWrapper());

      it('does not render the feedback link', () => {
        expect(findFeedbackLink().exists()).toBe(false);
      });
    });
  });
});
