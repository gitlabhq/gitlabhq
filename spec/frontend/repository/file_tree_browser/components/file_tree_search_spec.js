import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';
import FileTreeSearch from '~/repository/file_tree_browser/components/file_tree_search.vue';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { Mousetrap } from '~/lib/mousetrap';
import { FOCUS_FILE_TREE_BROWSER_FILTER_BAR, keysFor } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import HighlightedText from '~/vue_shared/components/highlighted_text.vue';

jest.mock('~/behaviors/shortcuts/shortcuts_toggle');

describe('FileTreeSearch', () => {
  let wrapper;
  let axiosMock = new AxiosMockAdapter(axios);
  const defaultMockFiles = [
    'app/models/user.rb',
    'app/controllers/users_controller.rb',
    'app/views/users/index.html.erb',
    'spec/models/user_spec.rb',
    'spec/controllers/users_controller_spec.rb',
    'config/routes.rb',
    'Gemfile',
    'README.md',
  ];
  const mockRouter = {
    push: jest.fn(),
  };

  const defaultProps = {
    projectPath: 'namespace/project',
    refType: 'heads',
    escapedRef: 'master',
  };

  const findLoadErrorMessage = () => wrapper.find('[data-testid="load-error-message"]');
  const findSearchInput = () => wrapper.find('[data-testid="file-tree-search-input"]');
  const findClearButton = () => wrapper.find('button[aria-label="Clear search"]');
  const findSearchPanel = () => wrapper.find('.file-tree-search-dropdown');
  const findResultsList = () => wrapper.find('[role="listbox"]');
  const findResultItems = () => wrapper.findAll('.file-tree-search-result-item');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findShortcutKey = () => wrapper.find('[data-testid="file-tree-search-shortcut-key"]');

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createComponent = (propsData = {}, options = {}) => {
    wrapper = shallowMount(FileTreeSearch, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      mocks: {
        $router: mockRouter,
      },
      stubs: {
        GlLoadingIcon,
        GlIcon,
      },
      attachTo: document.body,
      ...options,
    });
  };

  const triggerFilesLoad = async (mockFiles = defaultMockFiles) => {
    createComponent();
    axiosMock.onGet(`/namespace/project/-/files/master`).reply(200, mockFiles);
    findSearchInput().trigger('focus');
    await waitForPromises();
  };

  const triggerSearch = async (searchText) => {
    await findSearchInput().setValue(searchText);
    await nextTick();
  };

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('focuses the search input field and triggers tracking event when shortcut is triggered and is enabled', () => {
      shouldDisableShortcuts.mockReturnValue(false);
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      const mousetrapInstance = wrapper.vm.mousetrap;
      mousetrapInstance.trigger(keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR));

      expect(document.activeElement).toBe(findSearchInput().element);
      expect(trackEventSpy).toHaveBeenCalledWith(
        'focus_file_tree_browser_filter_bar_on_repository_page',
        { label: 'shortcut' },
        undefined,
      );
    });

    it('binds and unbinds mousetrap shortcut when shortcuts are enabled', () => {
      shouldDisableShortcuts.mockReturnValue(false);
      const bindSpy = jest.spyOn(Mousetrap.prototype, 'bind');
      const unbindSpy = jest.spyOn(Mousetrap.prototype, 'unbind');
      createComponent();

      expect(bindSpy).toHaveBeenCalledWith(
        keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR),
        wrapper.vm.focusSearchInput,
      );

      wrapper.destroy();
      expect(unbindSpy).toHaveBeenCalledWith(keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR));
    });

    it('does not bind mousetrap shortcut when shortcuts are disabled', () => {
      shouldDisableShortcuts.mockReturnValue(true);
      const bindSpy = jest.spyOn(Mousetrap.prototype, 'bind');
      createComponent();

      expect(bindSpy).not.toHaveBeenCalledWith();
    });

    it('renders shortcut key and search input with correct aria-keyshortcuts when shortcuts are enabled', () => {
      shouldDisableShortcuts.mockReturnValue(false);
      createComponent();

      expect(findShortcutKey().text()).toBe(keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR)[0]);
      expect(findSearchInput().attributes('aria-keyshortcuts')).toBe(
        keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR)[0],
      );
    });

    it('hides shortcut key after user enters text in the search input field', async () => {
      shouldDisableShortcuts.mockReturnValue(false);
      createComponent();
      await triggerSearch('users');

      expect(findShortcutKey().exists()).toBe(false);
    });

    it('does not set aria-keyshortcuts attribute when shortcuts are disabled', () => {
      shouldDisableShortcuts.mockReturnValue(true);
      createComponent();

      expect(findSearchInput().attributes('aria-keyshortcuts')).toBeUndefined();
    });

    it('renders search input field', () => {
      expect(findSearchInput().exists()).toBe(true);
    });

    it('does not render clear button when search is empty', () => {
      expect(findClearButton().exists()).toBe(false);
    });

    it('does not render search panel when search is empty', () => {
      expect(findSearchPanel().exists()).toBe(false);
    });

    it('shows clear button when search query is entered', async () => {
      await triggerSearch('users');

      expect(findClearButton().exists()).toBe(true);
    });

    it('triggers tracking event when search input field gets focused', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findSearchInput().trigger('focus');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'focus_file_tree_browser_filter_bar_on_repository_page',
        { label: 'click' },
        undefined,
      );
    });
  });

  describe('search functionality', () => {
    beforeEach(async () => {
      await triggerFilesLoad();
    });

    it('filters files by name', async () => {
      await triggerSearch('users');

      expect(findResultItems()).toHaveLength(4);
    });

    it('filter by name case-insensitively', async () => {
      await triggerSearch('USERS');

      expect(findResultItems()).toHaveLength(4);
    });

    it('limits results to 20 items', async () => {
      const customMockFiles = [];
      for (let i = 0; i < 23; i += 1) {
        customMockFiles.push(`app_controller_${i}.rb`);
      }
      await triggerFilesLoad(customMockFiles);
      await triggerSearch('app_controller');

      expect(findResultItems()).toHaveLength(20);
    });

    it('clears results and hides search panel when search is cleared', async () => {
      await triggerSearch('USER');
      expect(findResultItems()).toHaveLength(5);

      await triggerSearch('');
      expect(findResultItems()).toHaveLength(0);
      expect(findSearchPanel().exists()).toBe(false);
    });

    it('displays "No results found" message when no results', async () => {
      await triggerSearch('aalldlldlf');

      expect(wrapper.text()).toContain('No results found');
    });

    it('does not show search panel when input is focused but empty', () => {
      expect(findSearchPanel().exists()).toBe(false);
    });

    it('hides search panel and clears input field and focuses it when clear button is clicked', async () => {
      await triggerSearch('aalldlldlf');

      expect(findSearchInput().element.value).toBe('aalldlldlf');

      findClearButton().trigger('click');
      await nextTick();

      expect(document.activeElement).toBe(findSearchInput().element);
      expect(findSearchInput().element.value).toBe('');
      expect(findSearchPanel().exists()).toBe(false);
    });

    it('renders HighlightedText with file path and search query as match', async () => {
      await triggerSearch('user');

      const highlightedTexts = wrapper.findAllComponents(HighlightedText);
      expect(highlightedTexts.at(0).props('text')).toBe('app/models/user.rb');
      expect(highlightedTexts.at(0).props('match')).toBe('user');
    });

    it('navigates to file path, clears input and hides search panel when search result file is clicked', async () => {
      await triggerSearch('user');

      const firstResultItem = findResultItems().at(0);
      firstResultItem.find('button').trigger('click');
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith(
        '/-/blob/master/app/models/user.rb?ref_type=heads',
      );
      expect(findSearchInput().element.value).toBe('');
      expect(findSearchPanel().exists()).toBe(false);
    });
  });

  describe('keyboard navigation and focus', () => {
    beforeEach(async () => {
      await triggerFilesLoad();
    });

    it('navigates results with arrow down keys', async () => {
      await triggerSearch('users_controller');

      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();

      expect(document.activeElement).toBe(findResultItems().at(0).element);

      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();

      expect(document.activeElement).toBe(findResultItems().at(1).element);
    });

    it('navigates results with arrow up keys', async () => {
      await triggerSearch('users_controller');

      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();

      expect(document.activeElement).toBe(findResultItems().at(1).element);

      findSearchPanel().trigger('keydown', { key: 'ArrowUp' });
      await nextTick();

      expect(document.activeElement).toBe(findResultItems().at(0).element);
    });

    it('focus stays on last search result item when pressing arrow down key on it', async () => {
      await triggerSearch('users_controller');

      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();

      expect(document.activeElement).toBe(findResultItems().at(1).element);
    });

    it('focus moves to search input when pressing arrow up key on first search result item', async () => {
      await triggerSearch('users_controller');

      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      findSearchPanel().trigger('keydown', { key: 'ArrowUp' });
      await nextTick();

      expect(document.activeElement).toBe(findSearchInput().element);
    });

    it('focus stays on search input when pressing arrow up key while search input is already focused', async () => {
      await triggerSearch('users_controller');

      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      findSearchPanel().trigger('keydown', { key: 'ArrowUp' });
      findSearchPanel().trigger('keydown', { key: 'ArrowUp' });
      await nextTick();

      expect(document.activeElement).toBe(findSearchInput().element);
    });

    it('navigates to file path, clears input and hides search panel when enter is clicked on result item', async () => {
      await triggerSearch('user');

      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      findSearchPanel().trigger('keydown', { key: 'Enter' });
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith(
        '/-/blob/master/spec/models/user_spec.rb?ref_type=heads',
      );
      expect(findSearchInput().element.value).toBe('');
      expect(findSearchPanel().exists()).toBe(false);
    });

    it('resets focus when search results change', async () => {
      await triggerSearch('user');

      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();

      expect(document.activeElement).toBe(findResultItems().at(0).element);

      await triggerSearch('users_controller');

      expect(document.activeElement).not.toBe(findResultItems().at(0).element);
    });

    it('clears search input, hides panel and keep focus on input on escape key press when input is focused', async () => {
      await triggerSearch('user');

      findSearchInput().trigger('keydown', { key: 'Escape' });
      await nextTick();

      expect(findSearchInput().element.value).toBe('');
      expect(findSearchPanel().exists()).toBe(false);
      expect(document.activeElement).toBe(findSearchInput().element);
    });

    it('clears search input, hides panel and keep focus on input on escape key press when result item is focused', async () => {
      await triggerSearch('user');

      findSearchPanel().trigger('keydown', { key: 'ArrowDown' });
      findSearchPanel().trigger('keydown', { key: 'Escape' });
      await nextTick();

      expect(findSearchInput().element.value).toBe('');
      expect(findSearchPanel().exists()).toBe(false);
      expect(document.activeElement).toBe(findSearchInput().element);
    });
  });

  describe('files loading', () => {
    beforeEach(() => {
      createComponent();
      axiosMock = new AxiosMockAdapter(axios);
      axiosMock.onGet(`/namespace/project/-/files/master`).reply(200, defaultMockFiles);
    });

    it('does not load files on component creation', async () => {
      await waitForPromises();

      expect(axiosMock.history.get).toHaveLength(0);
    });

    it('loads files on search input focus only once', async () => {
      findSearchInput().trigger('focus');
      await waitForPromises();

      findSearchInput().trigger('focus');
      await waitForPromises();

      expect(axiosMock.history.get).toHaveLength(1);
      expect(axiosMock.history.get[0].url).toBe('/namespace/project/-/files/master');
    });

    it('hides loading icon after files are loaded', async () => {
      await findSearchInput().trigger('focus');
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays error message while searching if the files fails to load', async () => {
      createComponent();

      axiosMock.onGet(`/namespace/project/-/files/master`).reply(500);
      findSearchInput().trigger('focus');
      await waitForPromises();

      await triggerSearch('users');

      expect(findLoadErrorMessage().text()).toBe('Something went wrong while loading the files');
      expect(findResultsList().exists()).toBe(false);
    });
  });
});
