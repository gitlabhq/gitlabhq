import MockAdapter from 'axios-mock-adapter';
import { GlModal, GlSearchBoxByType, GlTab, GlEmptyState, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_TOO_MANY_REQUESTS,
} from '~/lib/utils/http_status';
import FeatureLibraryModal from '~/super_sidebar/components/feature_library/feature_library_modal.vue';
import FeatureLibraryItem from '~/super_sidebar/components/feature_library/feature_library_item.vue';
import {
  EVENT_OPEN_FEATURE_LIBRARY_MODAL,
  EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL,
  EVENT_CLICK_CATEGORY_TAB_IN_FEATURE_LIBRARY_MODAL,
  EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
} from '~/super_sidebar/tracking_constants';

jest.mock('~/sentry/sentry_browser_wrapper');
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

  const createWrapper = ({
    currentPinnedIds = [],
    panelType = 'project',
    showFeedbackLink = false,
    sections = defaultSections,
  } = {}) => {
    wrapper = shallowMountExtended(FeatureLibraryModal, {
      propsData: { sections, currentPinnedIds, showFeedbackLink },
      provide: { panelType },
      // Stub GlModal (declared props stay props, everything else surfaces as
      // attrs) and render all its slots so footer/body content is inspectable.
      stubs: { GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }) },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findTabLabels = () => findAllTabs().wrappers.map((w) => w.attributes('title'));
  const findItems = () => wrapper.findAllComponents(FeatureLibraryItem);
  const findItemIds = () => findItems().wrappers.map((w) => w.props('item').id);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findByTestId('search-loading');
  const findScrollArea = () => wrapper.findByTestId('feature-library-scroll-area');
  const findGrid = () => wrapper.findByTestId('feature-library-grid');
  const findFeedbackLink = () => wrapper.findComponent(GlLink);

  const emitSearch = async (query) => {
    await findSearch().vm.$emit('input', query);
  };

  describe('rendering', () => {
    beforeEach(() => createWrapper());

    it('renders an "All" tab plus one tab per section that has enriched items', () => {
      expect(findTabLabels()).toEqual(['All', 'Plan', 'Code', 'Manage']);
    });

    it('excludes settings menus', () => {
      expect(findTabLabels()).not.toContain('Settings');
    });

    it('wraps content in a flexible scroll area that fills available height and scrolls overflow', () => {
      const scrollArea = findScrollArea();
      expect(scrollArea.exists()).toBe(true);
      expect(scrollArea.classes()).toEqual(
        expect.arrayContaining([
          'feature-library-scroll-area',
          'gl-grow',
          'gl-min-h-0',
          'gl-overflow-y-auto',
        ]),
      );
    });

    it('renders a search input', () => {
      expect(findSearch().exists()).toBe(true);
    });

    it('debounces search input using the shared default interval', () => {
      expect(Number(findSearch().attributes('debounce'))).toBe(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    });

    it('lays the feature grid out responsively (one column on small viewports, scaling up)', () => {
      expect(findGrid().classes()).toEqual(
        expect.arrayContaining(['gl-grid-cols-1', 'sm:gl-grid-cols-2', 'md:gl-grid-cols-3']),
      );
    });

    it('adds a top margin above the search input', () => {
      expect(findSearch().classes()).toContain('gl-mt-3');
    });

    it('does not show a loading indicator by default', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('modal layout', () => {
    describe('with default props', () => {
      beforeEach(() => createWrapper());

      it('blurs the page behind the modal', () => {
        expect(findModal().props('modalClass')).toContain('gl-backdrop-blur-sm');
      });

      it('does not use centered so the top edge stays anchored during search', () => {
        expect(findModal().attributes('centered')).toBeUndefined();
      });

      it('caps its height so tall content scrolls internally', () => {
        expect(findModal().attributes('scrollable')).toBeDefined();
      });

      it('applies the feature-library-modal class for top-anchored positioning', () => {
        expect(findModal().props('modalClass')).toContain('feature-library-modal');
      });

      it('reserves a dismissable gutter around the dialog', () => {
        const modalClass = findModal().props('modalClass');
        expect(modalClass).toContain('gl-px-2');
        expect(modalClass).toContain('sm:gl-px-5');
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

  describe('filtering', () => {
    beforeEach(() => createWrapper());

    it('filters by active category (section)', async () => {
      await findAllTabs().at(1).vm.$emit('click');
      await nextTick();
      const categories = findItems().wrappers.map((w) => w.props('item').category);
      expect(categories.every((c) => c === 'plan_menu')).toBe(true);
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

      it('applies the active category filter to title matches', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        await emitSearch('items');
        await waitForPromises();

        await findAllTabs().at(2).vm.$emit('click');
        await nextTick();

        expect(findItems()).toHaveLength(0);
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

      it('excludes endpoint synonym results outside the active category', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['repository'] });
        await emitSearch('sprint');
        await waitForPromises();

        await findAllTabs().at(1).vm.$emit('click');
        await nextTick();

        expect(findItemIds()).not.toContain('repository');
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

    describe('active tab', () => {
      beforeEach(() => createWrapper());

      it('sets the active tab to "All" when a search is entered', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });

        await findAllTabs().at(1).vm.$emit('click');
        await nextTick();
        expect(findAllTabs().at(1).attributes('active')).toBe('true');

        await emitSearch('repo');
        await nextTick();

        expect(findAllTabs().at(0).attributes('active')).toBe('true');
        expect(findAllTabs().at(1).attributes('active')).toBeUndefined();
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

      it('uses the generic title when the "All" tab is active', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        await emitSearch('zzznomatch');
        await waitForPromises();

        expect(findEmptyState().props('title')).toBe('No features match your search');
      });

      it('uses a category-specific title when a category tab is active', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: [] });
        await emitSearch('items');
        await waitForPromises();

        // "items" matches "Work items" (Plan); the Code tab has no matches.
        await findAllTabs().at(2).vm.$emit('click');
        await nextTick();

        expect(findEmptyState().props('title')).toBe('No matches in Code');
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

      it('resets search, category, and endpoint state so reopening shows the full catalog', async () => {
        mockAxios.onGet(SEARCH_URL).reply(HTTP_STATUS_OK, { ids: ['boards'] });
        await emitSearch('sprint');
        await waitForPromises();
        await findAllTabs().at(1).vm.$emit('click');
        await nextTick();

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

    it('tracks clicking a category tab, labelled with the category id', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      await findAllTabs().at(1).vm.$emit('click');
      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_CLICK_CATEGORY_TAB_IN_FEATURE_LIBRARY_MODAL,
        { label: 'plan_menu' },
        CATEGORY,
      );
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
