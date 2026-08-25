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
  onboardingFeatureLibraryAiSearchPath: () => '/-/onboarding/feature_library/ai_search',
}));

const SEARCH_URL = '/-/onboarding/feature_library/search';
const AI_SEARCH_URL = '/-/onboarding/feature_library/ai_search';

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
  const focusItem = jest.fn();

  const createWrapper = ({
    currentPinnedIds = [],
    panelType = 'project',
    showFeedbackLink = false,
    sections = defaultSections,
    aiSearchAvailable = false,
    resourceId = null,
    supportsPins,
  } = {}) => {
    wrapper = shallowMountExtended(FeatureLibraryModal, {
      propsData: { sections, currentPinnedIds, showFeedbackLink, supportsPins },
      provide: { panelType, aiSearchAvailable, resourceId },
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
        FeatureLibraryItem: stubComponent(FeatureLibraryItem, { methods: { focus: focusItem } }),
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
  const findGeminiButton = () => wrapper.findComponentByTestId('search-with-gemini-button');
  const findGeminiSection = () => wrapper.findByTestId('gemini-results-grid');
  const findHideGeminiButton = () => wrapper.findComponentByTestId('hide-gemini-section');
  const findGeminiEmptyState = () => wrapper.findByTestId('gemini-empty-state');
  const findGeminiLoading = () => wrapper.findByTestId('gemini-loading');
  const findGeminiError = () => wrapper.findByTestId('gemini-error');
  const findGeminiStatusRegion = () => wrapper.findByTestId('gemini-status-region');
  const findGeminiItems = () =>
    findGeminiSection().exists()
      ? findGeminiSection().findAllComponents(FeatureLibraryItem)
      : { wrappers: [] };

  const emitSearch = async (query) => {
    await findSearch().vm.$emit('input', query);
  };

  const mockSearch = (response = { ids: [] }) =>
    mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, response);

  const mockAiSearch = (response = { ids: [], ai_search_available: true }) =>
    mockAxios.onGet(AI_SEARCH_URL).reply(HTTP_STATUS_OK, response);

  const clickGeminiSearch = async () => {
    await findGeminiButton().vm.$emit('click');
    await waitForPromises();
  };

  // Runs the main search, waits for it to settle, then triggers the Gemini
  // search from the resulting button. Bundles the repeated setup sequence
  // used across Gemini describe blocks.
  const runGeminiSearch = async (query) => {
    await emitSearch(query);
    await waitForPromises();
    await clickGeminiSearch();
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

        describe('when the gemini search button is not available', () => {
          beforeEach(() => {
            createWrapper({ showFeedbackLink: false, aiSearchAvailable: false, resourceId: 1 });
          });

          it('hides the footer', () => {
            expect(findModal().attributes('hide-footer')).toBe('true');
          });
        });

        describe('when the gemini search button is clicked', () => {
          beforeEach(async () => {
            mockSearch();
            mockAiSearch();

            createWrapper({ showFeedbackLink: false, aiSearchAvailable: true, resourceId: 1 });
            await emitSearch('re');
            await waitForPromises();
            await clickGeminiSearch();
          });

          it('hides the search button / footer', () => {
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

      // Ranking and sort order are unit-tested in search_spec.js. These two
      // cover the component's integration with the util via the real endpoint.
      it('ranks a title match above a synonym-only match from the endpoint', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['boards', 'repository'] });
        await emitSearch('repo');
        await waitForPromises();

        expect(findItemIds()).toEqual(['repository', 'boards']);
      });

      it('ranks a title match above a description-only match', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        await emitSearch('work');
        await waitForPromises();

        expect(findItemIds()).toEqual(['project_issue_list', 'boards']);
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

      it('passes the endpoint order through to synonym-only results', async () => {
        mockAxios
          .onGet(SEARCH_URL)
          .reply(HTTP_STATUS_OK, { ids: ['project_issue_list', 'boards'] });
        await emitSearch('sprint');
        await waitForPromises();

        expect(findItemIds()).toEqual(['project_issue_list', 'boards']);
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

  describe('"Search with Gemini" button', () => {
    describe('when aiSearchAvailable is false', () => {
      it('does not render the button', async () => {
        createWrapper({ aiSearchAvailable: false, resourceId: 1 });
        await emitSearch('something');
        expect(findGeminiButton().exists()).toBe(false);
      });
    });

    describe('when resourceId is absent', () => {
      it('does not render the button', async () => {
        createWrapper({ aiSearchAvailable: true, resourceId: null });
        await emitSearch('something');
        expect(findGeminiButton().exists()).toBe(false);
      });
    });

    describe('when query is shorter than 2 characters', () => {
      it('does not render the button', async () => {
        createWrapper({ aiSearchAvailable: true, resourceId: 1 });
        await emitSearch('r');
        expect(findGeminiButton().exists()).toBe(false);
      });
    });

    describe('when modal opens with no query', () => {
      it('does not render the button', () => {
        createWrapper({ aiSearchAvailable: true, resourceId: 1 });
        expect(findGeminiButton().exists()).toBe(false);
      });
    });

    describe('when available and query is active', () => {
      beforeEach(() => createWrapper({ aiSearchAvailable: true, resourceId: 1 }));

      it('renders the button once a query of 2+ chars is entered and the endpoint resolves', async () => {
        mockSearch();
        await emitSearch('re');
        await waitForPromises();
        expect(findGeminiButton().exists()).toBe(true);
      });

      it('renders the button even on zero matches (empty state)', async () => {
        mockSearch();
        await emitSearch('zzznomatch');
        await waitForPromises();
        expect(findEmptyState().exists()).toBe(true);
        expect(findGeminiButton().exists()).toBe(true);
      });

      it('shows the footer when the button is visible', async () => {
        mockSearch();
        await emitSearch('re');
        await waitForPromises();
        expect(findModal().attributes('hide-footer')).toBeUndefined();
      });
    });

    describe('after Gemini has been triggered', () => {
      beforeEach(async () => {
        mockSearch();
        mockAiSearch();
        createWrapper({ aiSearchAvailable: true, resourceId: 1 });

        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();
      });

      it('removes the button', () => {
        expect(findGeminiButton().exists()).toBe(false);
      });

      describe('when the query changes', () => {
        beforeEach(async () => {
          await emitSearch('repo');
          await waitForPromises();
        });

        it('restores the button', () => {
          expect(findGeminiButton().exists()).toBe(true);
        });
      });
    });
  });

  describe('Gemini section top border', () => {
    const findGeminiSectionWrapper = () => wrapper.findByTestId('gemini-section');

    beforeEach(() => {
      mockSearch();
      createWrapper({ aiSearchAvailable: true, resourceId: 1 });
    });

    describe('while Gemini is searching', () => {
      beforeEach(async () => {
        mockAxios.onGet(AI_SEARCH_URL).reply(() => new Promise(() => {}));
        await emitSearch('re');
        await waitForPromises();
        await findGeminiButton().vm.$emit('click');
        await nextTick();
      });

      it('is hidden', () => {
        expect(findGeminiSectionWrapper().classes()).not.toContain('gl-border-t');
      });
    });

    describe('once Gemini returns results', () => {
      beforeEach(async () => {
        mockAiSearch({ ids: ['boards'], ai_search_available: true });
        await runGeminiSearch('re');
      });

      it('is shown', () => {
        expect(findGeminiSectionWrapper().classes()).toContain('gl-border-t');
      });
    });

    describe('on the Gemini empty state', () => {
      beforeEach(async () => {
        mockAiSearch();
        await runGeminiSearch('zzznomatch');
      });

      it('is hidden', () => {
        expect(findGeminiEmptyState().exists()).toBe(true);
        expect(findGeminiSectionWrapper().classes()).not.toContain('gl-border-t');
      });
    });

    describe('when Gemini returns an error', () => {
      beforeEach(async () => {
        mockAxios.onGet(AI_SEARCH_URL).reply(HTTP_STATUS_TOO_MANY_REQUESTS);
        await runGeminiSearch('re');
      });

      it('is shown', () => {
        expect(findGeminiSectionWrapper().classes()).toContain('gl-border-t');
      });
    });
  });

  describe('Gemini status live region mount timing', () => {
    // Some screen readers only announce *changes* to a live region already
    // present in the DOM; content that exists the moment the region is first
    // inserted can be silently skipped. The region must therefore be mounted
    // before showGeminiSection becomes true, not gated behind it.
    it('is present in the DOM even when the Gemini section is not shown', () => {
      createWrapper();

      expect(findGeminiStatusRegion().exists()).toBe(true);
      expect(findGeminiStatusRegion().text()).toBe('');
    });
  });

  describe('Gemini search', () => {
    const RESOURCE_ID = 42;

    beforeEach(() => {
      mockSearch();
      createWrapper({ aiSearchAvailable: true, resourceId: RESOURCE_ID, panelType: 'project' });
    });

    describe('while the request is in flight', () => {
      beforeEach(async () => {
        mockAxios.onGet(AI_SEARCH_URL).reply(() => new Promise(() => {}));
        await emitSearch('re');
        await waitForPromises();

        await findGeminiButton().vm.$emit('click');
        await nextTick();
      });

      it('shows the loading state and hides the button, results, and empty state', () => {
        expect(findGeminiLoading().exists()).toBe(true);
        expect(findGeminiButton().exists()).toBe(false);
        expect(findGeminiSection().exists()).toBe(false);
        expect(findGeminiEmptyState().exists()).toBe(false);
      });

      it('does not render the "Suggested by Gemini" header or Hide button', () => {
        expect(findHideGeminiButton().exists()).toBe(false);
      });

      it('does not render the generic empty state, even though the main search has no matches', () => {
        expect(findEmptyState().exists()).toBe(false);
      });

      it('returns keyboard focus to the search input, since the button unmounts', () => {
        expect(focusInput).toHaveBeenCalled();
      });

      it('announces the searching state via the status live region', () => {
        expect(findGeminiStatusRegion().attributes('aria-live')).toBe('polite');
        expect(findGeminiStatusRegion().attributes('aria-atomic')).toBe('true');
        expect(findGeminiStatusRegion().text()).toBe('Searching with Gemini …');
      });
    });

    describe('when the request resolves with results', () => {
      beforeEach(async () => {
        mockAiSearch({ ids: ['boards'], ai_search_available: true });
        await emitSearch('re');
        await waitForPromises();

        await clickGeminiSearch();
      });

      it('hides the loading state', () => {
        expect(findGeminiLoading().exists()).toBe(false);
        expect(findGeminiSection().exists()).toBe(true);
      });

      it('renders the hide button', () => {
        expect(findGeminiSection().exists()).toBe(true);
        expect(findHideGeminiButton().exists()).toBe(true);
      });

      it('announces that matching features were found via the status live region', () => {
        expect(findGeminiStatusRegion().text()).toBe('Gemini found matching features.');
      });
    });

    describe('when the request resolves empty', () => {
      beforeEach(async () => {
        mockAiSearch();
        await emitSearch('re');
        await waitForPromises();

        await clickGeminiSearch();
      });

      it('hides the loading state', () => {
        expect(findGeminiLoading().exists()).toBe(false);
        expect(findGeminiEmptyState().exists()).toBe(true);
      });

      it('announces the empty state via the status live region', () => {
        expect(findGeminiStatusRegion().text()).toBe(
          "Gemini couldn't find a matching feature. Try different keywords.",
        );
      });
    });

    describe('when Gemini returns matching ids', () => {
      beforeEach(async () => {
        await emitSearch('repo');
        await waitForPromises();
        // 'boards' is in the catalog but NOT a text match for 'repo', so it surfaces as a Gemini result.
        mockAiSearch({ ids: ['boards', 'repository'], ai_search_available: true });
        await clickGeminiSearch();
      });

      it('sends query, panel, and resource_id to the ai_search endpoint', () => {
        const req = mockAxios.history.get.find((r) => r.url === AI_SEARCH_URL);
        expect(req.params).toMatchObject({
          query: 'repo',
          panel: 'project',
          resource_id: RESOURCE_ID,
        });
      });

      it('renders the Gemini results section', () => {
        expect(findGeminiSection().exists()).toBe(true);
      });

      it('deduplicates: omits ids already shown in the main grid', () => {
        // 'repository' is a direct text match for 'repo' so it should not appear in the Gemini section.
        const geminiIds = findGeminiItems().wrappers.map((w) => w.props('item').id);
        expect(geminiIds).not.toContain('repository');
        expect(geminiIds).toContain('boards');
      });
    });

    describe('when Gemini returns no results', () => {
      describe('and the main search also has no results', () => {
        it('shows only the Gemini empty state, not the generic empty state', async () => {
          mockAiSearch();
          await emitSearch('zzznomatch');
          await waitForPromises();
          await clickGeminiSearch();

          expect(findGeminiSection().exists()).toBe(false);
          expect(findGeminiEmptyState().exists()).toBe(true);
          expect(findGeminiEmptyState().text()).toBe(
            "Gemini couldn't find a matching feature. Try different keywords.",
          );
          expect(findEmptyState().exists()).toBe(false);
        });
      });

      describe('and the main search has results', () => {
        it('shows the main grid and the Gemini empty state', async () => {
          mockAiSearch();
          await emitSearch('repo');
          await waitForPromises();
          await clickGeminiSearch();

          expect(findGrid().exists()).toBe(true);
          expect(findGeminiSection().exists()).toBe(false);
          expect(findGeminiEmptyState().exists()).toBe(true);
        });
      });

      it('does not render the Gemini results section', async () => {
        mockAiSearch();
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();
        expect(findGeminiSection().exists()).toBe(false);
      });
    });

    describe('when the main search has no results but Gemini has results', () => {
      it('shows the generic empty state and the Gemini results section', async () => {
        await emitSearch('zzznomatch');
        await waitForPromises();
        expect(findEmptyState().exists()).toBe(true);

        mockAiSearch({ ids: ['repository'], ai_search_available: true });
        await clickGeminiSearch();

        expect(findEmptyState().exists()).toBe(true);
        expect(findGeminiSection().exists()).toBe(true);
        expect(findGeminiEmptyState().exists()).toBe(false);
      });
    });

    describe('when the ai_search rate limit is exceeded (429)', () => {
      it('surfaces the rate limit error and does not report to Sentry', async () => {
        mockAxios.onGet(AI_SEARCH_URL).reply(HTTP_STATUS_TOO_MANY_REQUESTS, {
          error: 'This endpoint has been requested too many times. Try again later.',
        });
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();

        expect(findGeminiSection().exists()).toBe(false);
        expect(findGeminiEmptyState().exists()).toBe(false);
        expect(findGeminiError().exists()).toBe(true);
        expect(findGeminiError().text()).toBe(
          'This endpoint has been requested too many times. Try again later.',
        );
        expect(Sentry.captureException).not.toHaveBeenCalled();
      });

      it('announces the error via the status live region', async () => {
        mockAxios.onGet(AI_SEARCH_URL).reply(HTTP_STATUS_TOO_MANY_REQUESTS, {
          error: 'This endpoint has been requested too many times. Try again later.',
        });
        await runGeminiSearch('re');

        expect(findGeminiStatusRegion().text()).toBe(
          'This endpoint has been requested too many times. Try again later.',
        );
      });

      it('falls back to a generic rate limit message when the server does not provide one', async () => {
        mockAxios.onGet(AI_SEARCH_URL).reply(HTTP_STATUS_TOO_MANY_REQUESTS);
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();

        expect(findGeminiError().text()).toBe(
          'You have reached the search limit. Try again later.',
        );
      });
    });

    describe('when the request fails unexpectedly', () => {
      it('surfaces a generic error and reports to Sentry', async () => {
        mockAxios.onGet(AI_SEARCH_URL).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();

        expect(findGeminiSection().exists()).toBe(false);
        expect(findGeminiEmptyState().exists()).toBe(false);
        expect(findGeminiError().exists()).toBe(true);
        expect(findGeminiError().text()).toBe(
          'Something went wrong searching with Gemini. Try again.',
        );
        expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error), {
          tags: { feature_category: 'onboarding' },
        });
      });
    });

    describe('retrying after an error', () => {
      it('keeps the "Search with Gemini" button available so the user can retry', async () => {
        mockAxios.onGet(AI_SEARCH_URL).reply(HTTP_STATUS_TOO_MANY_REQUESTS);
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();

        expect(findGeminiError().exists()).toBe(true);
        expect(findGeminiButton().exists()).toBe(true);
      });

      it('clears the previous error once the retry succeeds', async () => {
        mockAxios.onGet(AI_SEARCH_URL).replyOnce(HTTP_STATUS_TOO_MANY_REQUESTS);
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();
        expect(findGeminiError().exists()).toBe(true);

        mockAiSearch({ ids: ['boards'], ai_search_available: true });
        await clickGeminiSearch();

        expect(findGeminiError().exists()).toBe(false);
        expect(findGeminiSection().exists()).toBe(true);
      });
    });

    describe('Hide button', () => {
      beforeEach(async () => {
        mockAiSearch({ ids: ['boards'], ai_search_available: true });
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();
      });

      it('renders a Hide button inside the Gemini section', () => {
        expect(findHideGeminiButton().exists()).toBe(true);
      });

      it('dismisses the Gemini section when clicked', async () => {
        await findHideGeminiButton().vm.$emit('click');
        expect(findGeminiSection().exists()).toBe(false);
      });

      it('clears the status live region instead of leaving stale text', async () => {
        await findHideGeminiButton().vm.$emit('click');
        expect(findGeminiStatusRegion().text()).toBe('');
      });

      it('returns keyboard focus to the search input, since the Hide button unmounts', async () => {
        focusInput.mockClear();
        await findHideGeminiButton().vm.$emit('click');
        expect(focusInput).toHaveBeenCalled();
      });

      it('re-offers the search CTA after Hide is clicked, without changing the query', async () => {
        expect(findGeminiButton().exists()).toBe(false);

        await findHideGeminiButton().vm.$emit('click');

        expect(findGeminiSection().exists()).toBe(false);
        expect(findGeminiButton().exists()).toBe(true);
      });

      it('re-runs the Gemini search in place when the CTA is clicked again after Hide', async () => {
        await findHideGeminiButton().vm.$emit('click');
        expect(findGeminiButton().exists()).toBe(true);

        await clickGeminiSearch();

        expect(findGeminiSection().exists()).toBe(true);
        expect(findGeminiButton().exists()).toBe(false);
      });

      it('restores the Gemini section when the query changes and Gemini is re-triggered', async () => {
        await findHideGeminiButton().vm.$emit('click');

        await emitSearch('repo');
        await waitForPromises();
        await clickGeminiSearch();
        expect(findGeminiSection().exists()).toBe(true);
      });
    });

    describe('Hide button on the Gemini empty state', () => {
      beforeEach(async () => {
        mockAiSearch();
        await emitSearch('zzznomatch');
        await waitForPromises();
        await clickGeminiSearch();
      });

      it('shows the Gemini empty state before Hide is clicked', () => {
        expect(findGeminiEmptyState().exists()).toBe(true);
        expect(findEmptyState().exists()).toBe(false);
      });

      it('shows the original (generic) empty state instead of nothing after Hide is clicked', async () => {
        await findHideGeminiButton().vm.$emit('click');

        expect(findGeminiEmptyState().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('re-offers the search CTA after Hide is clicked', async () => {
        expect(findGeminiButton().exists()).toBe(false);

        await findHideGeminiButton().vm.$emit('click');

        expect(findGeminiButton().exists()).toBe(true);
      });
    });

    describe('on modal hidden', () => {
      it('resets the Gemini section, results, and button back to their initial state', async () => {
        mockAiSearch({ ids: ['boards'], ai_search_available: true });
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();
        expect(findGeminiSection().exists()).toBe(true);
        expect(findGeminiButton().exists()).toBe(false);

        findModal().vm.$emit('hidden');
        await nextTick();

        // Re-opening and re-searching should behave as if Gemini was never triggered:
        // results are cleared and the button is offered again.
        findModal().vm.$emit('shown');
        await emitSearch('re');
        await waitForPromises();

        expect(findGeminiSection().exists()).toBe(false);
        expect(findGeminiButton().exists()).toBe(true);
      });
    });

    describe('stale response handling', () => {
      it('ignores a stale response when the query changed mid-flight', async () => {
        let resolveRequest;
        mockAxios.onGet(AI_SEARCH_URL).reply(
          () =>
            new Promise((resolve) => {
              resolveRequest = resolve;
            }),
        );
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();

        // The user changes the query while the original request is still in flight.
        await emitSearch('other');
        await waitForPromises();

        // The stale response for the old query lands after the query has changed.
        resolveRequest([HTTP_STATUS_OK, { ids: ['boards'], ai_search_available: true }]);
        await waitForPromises();

        expect(findGeminiSection().exists()).toBe(false);
        expect(findGeminiButton().exists()).toBe(true);
      });

      it('does not report a superseded response error to Sentry', async () => {
        let rejectRequest;
        mockAxios.onGet(AI_SEARCH_URL).reply(
          () =>
            new Promise((_resolve, reject) => {
              rejectRequest = reject;
            }),
        );
        await emitSearch('re');
        await waitForPromises();
        await clickGeminiSearch();

        await emitSearch('other');
        await waitForPromises();

        rejectRequest({ response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR } });
        await waitForPromises();

        expect(Sentry.captureException).not.toHaveBeenCalled();
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
    const pressEnter = () => {
      findSearch().vm.$emit('keydown', new KeyboardEvent('keydown', { key: 'Enter' }));
    };

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

      it('focuses the first displayed result on Enter, without navigating or closing the modal', () => {
        pressEnter();

        // Assert identity, not just that some item was focused: focusItem is
        // one shared mock across every stubbed item, and $refs.searchResultItems[0]
        // (Vue 2 v-for ref array registration order) isn't guaranteed to track
        // the current filteredItems order, so this also guards the ref-ordering fix.
        expect(focusItem).toHaveBeenCalled();
        expect(focusItem.mock.contexts[0].item.id).toBe('boards');
        expect(visitUrl).not.toHaveBeenCalled();
        expect(hideModal).not.toHaveBeenCalled();
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

      it('does not focus a result on Enter', () => {
        pressEnter();

        expect(focusItem).not.toHaveBeenCalled();
      });
    });

    describe('when synonym matches exist', () => {
      beforeEach(async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['members'] });
        createWrapper();
        await emitSearch('sprint');
        await waitForPromises();
      });

      it('focuses the first displayed result on Enter', () => {
        pressEnter();

        expect(focusItem).toHaveBeenCalled();
        expect(focusItem.mock.contexts[0].item.id).toBe('members');
      });
    });

    describe('when the query is empty', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('does nothing on Enter', () => {
        pressEnter();

        expect(focusItem).not.toHaveBeenCalled();
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

        expect(focusItem).not.toHaveBeenCalled();
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

        expect(focusItem).not.toHaveBeenCalled();
      });
    });

    describe('when the first displayed result has no link', () => {
      beforeEach(async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        createWrapper();
        // 'milestones' has no link in defaultSections and is the only match.
        await emitSearch('milestones');
        await waitForPromises();
      });

      it('delegates to focus(), which intentionally no-ops for link-less items, rather than navigating', () => {
        // The no-op here is intentional: a link-less item isn't navigable, so
        // there's nothing to focus into for that row. The modal itself
        // doesn't special-case this — FeatureLibraryItem#focus() is a no-op
        // when there's no title link to focus (see feature_library_item_spec.js).
        pressEnter();

        expect(focusItem).toHaveBeenCalled();
        expect(visitUrl).not.toHaveBeenCalled();
        expect(hideModal).not.toHaveBeenCalled();
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

    it('does not track a navigate event on Enter in the search box, since it only focuses the first result', async () => {
      mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
      await emitSearch('board');
      await waitForPromises();

      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findSearch().vm.$emit('keydown', new KeyboardEvent('keydown', { key: 'Enter' }));

      expect(trackEventSpy).not.toHaveBeenCalledWith(
        EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
        expect.anything(),
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

    // The Gemini search tracking assertion lives in the EE spec because the
    // search_with_gemini_in_feature_library_modal event definition is EE-only
    // (tiers: premium, ultimate) and lives in ee/config/events/:
    // ee/spec/frontend/super_sidebar/components/feature_library_modal_spec.js
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

  describe('destroy', () => {
    it('cancels a pending reveal animation frame', () => {
      createWrapper();
      const cancelSpy = jest.spyOn(window, 'cancelAnimationFrame');

      wrapper.vm.renderLimit = 0;
      wrapper.vm.revealRemainingItems();
      const scheduledFrameId = wrapper.vm.revealFrameId;
      expect(scheduledFrameId).not.toBeNull();

      wrapper.destroy();

      expect(cancelSpy).toHaveBeenCalledWith(scheduledFrameId);
    });
  });
});
