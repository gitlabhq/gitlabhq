import Vue, { nextTick } from 'vue';
import { GlTooltip } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { cloneDeep } from 'lodash';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import TreeList from '~/repository/file_tree_browser/components/tree_list.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import { FOCUS_FILE_TREE_BROWSER_FILTER_BAR, keysFor } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import { Mousetrap } from '~/lib/mousetrap';
import { waitForElement } from '~/lib/utils/dom_utils';
import refQuery from '~/repository/queries/ref.query.graphql';
import FileTreeBrowserToggle from '~/repository/file_tree_browser/components/file_tree_browser_toggle.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import { mockResponse } from '../mock_data';

Vue.use(VueApollo);
Vue.use(PiniaVuePlugin);

jest.mock('~/repository/utils/ref_type', () => ({ getRefType: jest.fn(() => 'MOCK_REF_TYPE') }));
jest.mock('~/lib/utils/url_utility', () => ({
  joinPaths: jest.fn((...args) => args.join('/').replace(/\/+/g, '/')),
  buildURLwithRefType: jest.fn(({ path, refType }) =>
    refType ? `${path}?ref_type=${refType.toLowerCase()}` : path,
  ),
  visitUrl: jest.fn(),
}));
jest.mock('~/behaviors/shortcuts/shortcuts_toggle');
jest.mock('~/lib/utils/dom_utils');

describe('Tree List', () => {
  let wrapper;
  let apolloProvider;
  let pinia;
  let getQueryHandlerSuccess;

  const { trigger: triggerIntersection } = useMockIntersectionObserver();
  const triggerIntersectionForAll = () => {
    const listItems = wrapper.element.querySelectorAll('[data-item-id]');
    listItems.forEach((item) => {
      triggerIntersection(item, { entry: { isIntersecting: true } });
    });
  };

  const createComponent = async (apiResponse = mockResponse, options = {}) => {
    const currentRef = 'main';
    getQueryHandlerSuccess = jest.fn().mockResolvedValue(apiResponse);

    apolloProvider = createMockApollo([[paginatedTreeQuery, getQueryHandlerSuccess]]);
    apolloProvider.defaultClient.cache.writeQuery({
      query: refQuery,
      data: { ref: currentRef, escapedRef: currentRef },
    });
    wrapper = shallowMountExtended(TreeList, {
      apolloProvider,
      pinia,
      propsData: {
        projectPath: 'group/project',
        currentRef: 'main',
        refType: 'heads',
        ...options.propsData,
      },
      mocks: {
        $router: { push: jest.fn() },
        $route: { params: {}, $apollo: { query: jest.fn() }, ...options.mocks?.$route },
      },
    });

    await waitForPromises();
    triggerIntersectionForAll();
  };

  beforeEach(() => {
    pinia = createTestingPinia();
    return createComponent();
  });

  const findFileTreeToggle = () => wrapper.findComponent(FileTreeBrowserToggle);
  const findTree = () => wrapper.find('[role="tree"]');
  const findHeader = () => wrapper.find('h3');
  const findTreeItems = () => wrapper.findAll('[role="treeitem"]');
  const findFileRows = () => wrapper.findAllComponents(FileRow);
  const findFileRowPlaceholders = () => wrapper.findAll('[data-placeholder-item]');
  const findSearchButton = () => wrapper.findByTestId('search-trigger');
  const findTooltip = () => wrapper.findComponent(GlTooltip);

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  it('calls apollo query with correct parameters', () => {
    expect(getQueryHandlerSuccess).toHaveBeenCalledWith({
      projectPath: 'group/project',
      ref: 'main',
      refType: 'MOCK_REF_TYPE',
      path: '/',
      nextPageCursor: '',
      pageSize: 100,
    });
  });

  it('renders a title', () => {
    expect(findHeader().text()).toBe('Files');
  });

  it('renders file tree browser toggle', () => {
    expect(findFileTreeToggle().exists()).toBe(true);
  });

  it('renders file rows with correct props', () => {
    const fileRows = findFileRows();

    expect(fileRows.at(0).props()).toMatchObject({
      file: {
        id: '/dir_1/dir_2-gid://123-0',
        level: 0,
        name: 'dir_2',
        path: '/dir_1/dir_2',
        routerPath: '/-/tree/main/dir_1/dir_2?ref_type=heads',
        type: 'tree',
      },
      fileUrl: '/-/tree/main/dir_1/dir_2?ref_type=heads',
      level: 0,
    });

    // File row
    expect(fileRows.at(1).props()).toMatchObject({
      file: {
        fileHash: 'abc123',
        id: '/dir_1/file.txt-gid://456-0',
        level: 0,
        mode: '100644',
        name: 'file.txt',
        path: '/dir_1/file.txt',
        routerPath: '/-/blob/main/dir_1/file.txt?ref_type=heads',
      },
      fileUrl: '/-/blob/main/dir_1/file.txt?ref_type=heads',
      level: 0,
    });
  });

  it('fetches directory contents when tree row is clicked', async () => {
    const subdirResponse = cloneDeep(mockResponse);
    subdirResponse.data.project.repository.paginatedTree.nodes[0].trees.nodes = [];
    subdirResponse.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [];
    getQueryHandlerSuccess.mockResolvedValueOnce(subdirResponse);

    findFileRows().at(0).vm.$emit('clickTree');
    await waitForPromises();

    expect(getQueryHandlerSuccess).toHaveBeenLastCalledWith(
      expect.objectContaining({ path: 'dir_1/dir_2' }),
    );
  });

  it.each`
    toggleClose  | expectedOpened | description
    ${true}      | ${false}       | ${'collapses'}
    ${false}     | ${true}        | ${'stays expanded'}
    ${undefined} | ${false}       | ${'collapses (default behavior)'}
  `(
    '$description when clicked with toggleClose: $toggleClose',
    async ({ toggleClose, expectedOpened }) => {
      await createComponent();
      const subdirResponse = cloneDeep(mockResponse);
      subdirResponse.data.project.repository.paginatedTree.nodes[0].trees.nodes = [];
      subdirResponse.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [];
      getQueryHandlerSuccess.mockResolvedValueOnce(subdirResponse);

      findFileRows().at(0).vm.$emit('clickTree');
      await waitForPromises();

      expect(findFileRows().at(0).props('file').opened).toBe(true);

      const options = toggleClose === undefined ? undefined : { toggleClose };
      findFileRows().at(0).vm.$emit('clickTree', options);
      await nextTick();

      expect(findFileRows().at(0).props('file').opened).toBe(expectedOpened);
    },
  );

  it('sets aria-setsize and aria-posinset relative to siblings at same level', async () => {
    await createComponent();
    const treeItems = findTreeItems();

    expect(treeItems.at(0).attributes('aria-setsize')).toBe('2');
    expect(treeItems.at(0).attributes('aria-posinset')).toBe('1');

    expect(treeItems.at(1).attributes('aria-setsize')).toBe('2');
    expect(treeItems.at(1).attributes('aria-posinset')).toBe('2');
  });

  describe('pagination', () => {
    beforeEach(() => {
      const paginatedResponse = cloneDeep(mockResponse);
      paginatedResponse.data.project.repository.paginatedTree.pageInfo.hasNextPage = true;
      return createComponent(paginatedResponse);
    });

    it('renders a show more button when hasNextPage is true', () => {
      expect(findFileRows().at(2).props('file')).toMatchObject({ isShowMore: true });
    });

    it('fetches the next page', async () => {
      const secondPageResponse = cloneDeep(mockResponse);
      secondPageResponse.data.project.repository.paginatedTree.nodes[0].trees.nodes = [];
      secondPageResponse.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [];
      getQueryHandlerSuccess.mockResolvedValueOnce(secondPageResponse);

      const mockFocus = jest.fn();
      const mockEvent = {
        target: {
          closest: jest.fn(() => ({
            previousElementSibling: {
              nextElementSibling: {
                focus: mockFocus,
              },
            },
          })),
        },
      };

      findFileRows().at(2).vm.$emit('showMore', mockEvent);

      await waitForPromises();

      expect(getQueryHandlerSuccess).toHaveBeenCalledWith({
        projectPath: 'group/project',
        ref: 'main',
        refType: 'MOCK_REF_TYPE',
        path: '/',
        nextPageCursor: 'cursor123',
        pageSize: 100,
      });

      expect(mockFocus).toHaveBeenCalled();
    });
  });

  describe('search button', () => {
    it('renders search button with correct props', () => {
      const button = findSearchButton();

      expect(button.props('icon')).toBe('search');
      expect(button.attributes('aria-label')).toBe('Search files (*.vue, *.rb...)');
      expect(button.text()).toBe('Search files (*.vue, *.rb...)');
    });

    it('dispatches global search event when search button is clicked', async () => {
      const dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');
      const mockSearchInput = document.createElement('input');
      mockSearchInput.id = 'search';
      waitForElement.mockResolvedValue(mockSearchInput);

      findSearchButton().vm.$emit('click');
      await nextTick();

      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'globalSearch:open',
        }),
      );
    });

    it('sets search input value to "~" after opening global search', async () => {
      const mockSearchInput = document.createElement('input');
      mockSearchInput.id = 'search';
      waitForElement.mockResolvedValue(mockSearchInput);

      findSearchButton().vm.$emit('click');
      await waitForPromises();

      expect(mockSearchInput.value).toBe('~');
    });

    it('dispatches input event on search input after setting value', async () => {
      const mockSearchInput = document.createElement('input');
      mockSearchInput.id = 'search';
      const dispatchEventSpy = jest.spyOn(mockSearchInput, 'dispatchEvent');
      waitForElement.mockResolvedValue(mockSearchInput);

      findSearchButton().vm.$emit('click');
      await waitForPromises();

      expect(dispatchEventSpy).toHaveBeenCalledWith(expect.any(Event));
      expect(dispatchEventSpy.mock.calls[0][0].type).toBe('input');
    });

    it('triggers a tracking event when search button is clicked', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findSearchButton().vm.$emit('click');
      await nextTick();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'focus_file_tree_browser_filter_bar_on_repository_page',
        { label: 'click' },
        undefined,
      );
    });
  });

  describe('handles search button focus correctly when shortcuts are enabled', () => {
    beforeEach(() => {
      shouldDisableShortcuts.mockReturnValue(false);
      createComponent();
    });

    it('opens global search when shortcut is triggered', async () => {
      const dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');
      const mockSearchInput = document.createElement('input');
      mockSearchInput.id = 'search';
      waitForElement.mockResolvedValue(mockSearchInput);

      const mousetrapInstance = wrapper.vm.mousetrap;
      mousetrapInstance.trigger('f');

      await waitForPromises();

      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'globalSearch:open',
        }),
      );
      expect(mockSearchInput.value).toBe('~');
    });

    it('triggers a tracking event when shortcut is used', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const mockSearchInput = document.createElement('input');
      mockSearchInput.id = 'search';
      waitForElement.mockResolvedValue(mockSearchInput);

      const mousetrapInstance = wrapper.vm.mousetrap;
      mousetrapInstance.trigger('f');

      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'focus_file_tree_browser_filter_bar_on_repository_page',
        { label: 'shortcut' },
        undefined,
      );
    });

    it('displays tooltip', () => {
      createComponent();
      expect(findTooltip().exists()).toBe(true);
    });

    it('binds and unbinds Mousetrap shortcut', () => {
      const bindSpy = jest.spyOn(Mousetrap.prototype, 'bind');
      const unbindSpy = jest.spyOn(Mousetrap.prototype, 'unbind');

      createComponent();
      expect(bindSpy).toHaveBeenCalledWith(
        keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR),
        wrapper.vm.triggerFocusFilterBar,
      );

      wrapper.destroy();
      expect(unbindSpy).toHaveBeenCalledWith(keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR));
    });

    it('sets correct aria-keyshortcuts attribute on search button', () => {
      const button = findSearchButton();
      expect(button.attributes('aria-keyshortcuts')).toBe(
        keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR)[0],
      );
    });
  });

  describe('handles search button focus correctly when shortcuts are disabled', () => {
    beforeEach(() => {
      shouldDisableShortcuts.mockReturnValue(true);
      createComponent();
    });

    it('does not open global search when shortcuts are disabled', async () => {
      const dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

      const mousetrapInstance = wrapper.vm.mousetrap;
      mousetrapInstance.trigger('f');

      await nextTick();

      expect(dispatchEventSpy).not.toHaveBeenCalled();
    });

    it('does not display tooltip', () => {
      createComponent();
      expect(findTooltip().exists()).toBe(false);
    });

    it('does not bind mousetrap shortcut when shortcuts are disabled', () => {
      const bindSpy = jest.spyOn(Mousetrap.prototype, 'bind');

      expect(bindSpy).not.toHaveBeenCalledWith(
        keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR),
        wrapper.vm.triggerFocusFilterBar,
      );
    });

    it('does not set aria-keyshortcuts attribute on search button', () => {
      const button = findSearchButton();
      expect(button.attributes('aria-keyshortcuts')).toBeUndefined();
    });
  });

  describe('deep path navigation with pagination', () => {
    it('paginates to find directories not on first page', async () => {
      const page1 = cloneDeep(mockResponse);
      page1.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [];
      page1.data.project.repository.paginatedTree.pageInfo = {
        __typename: 'PageInfo',
        hasNextPage: true,
        startCursor: null,
        endCursor: 'page1_cursor',
      };

      const page2 = cloneDeep(mockResponse);
      page2.data.project.repository.paginatedTree.nodes[0].trees.nodes = [
        { id: 'gid://dir_100', name: 'dir_100', path: 'dir_100', webPath: 'dir_100' },
      ];

      const dir100Contents = cloneDeep(mockResponse);
      dir100Contents.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [
        {
          id: 'gid://file',
          name: 'file.txt',
          path: 'dir_100/file.txt',
          sha: 'abc123',
          webPath: 'dir_100/file.txt',
        },
      ];

      getQueryHandlerSuccess
        .mockResolvedValueOnce(page1) // Root page 1
        .mockResolvedValueOnce(page2) // Root page 2
        .mockResolvedValueOnce(dir100Contents); // dir_100 contents

      wrapper = shallowMountExtended(TreeList, {
        apolloProvider: createMockApollo([[paginatedTreeQuery, getQueryHandlerSuccess]]),
        propsData: { projectPath: 'group/project', currentRef: 'main' },
        mocks: { $route: { params: { path: 'dir_100/file.txt' } } },
      });

      await waitForPromises();
      expect(getQueryHandlerSuccess).toHaveBeenCalledTimes(3);
    });

    it('respects default maxPages limit (5)', async () => {
      getQueryHandlerSuccess.mockReset();

      for (let i = 0; i < 10; i += 1) {
        const page = cloneDeep(mockResponse);
        page.data.project.repository.paginatedTree.pageInfo = {
          __typename: 'PageInfo',
          hasNextPage: i < 9,
          startCursor: null,
          endCursor: `cursor_${i}`,
        };

        page.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [];
        page.data.project.repository.paginatedTree.nodes[0].trees.nodes = [];
        getQueryHandlerSuccess.mockResolvedValueOnce(page);
      }

      wrapper = shallowMountExtended(TreeList, {
        apolloProvider: createMockApollo([[paginatedTreeQuery, getQueryHandlerSuccess]]),
        propsData: { projectPath: 'group/project', currentRef: 'main' },
        mocks: { $route: { params: { path: 'dir_99/file.txt' } } },
      });

      await waitForPromises();
      expect(getQueryHandlerSuccess).toHaveBeenCalledTimes(6); // 1 + 5 pages
    });

    it('respects default maxDepth limit (20)', async () => {
      const deepPath = Array.from({ length: 30 }, (_, i) => `dir_${i}`).join('/');

      wrapper = shallowMountExtended(TreeList, {
        apolloProvider: createMockApollo([[paginatedTreeQuery, getQueryHandlerSuccess]]),
        propsData: { projectPath: 'group/project', currentRef: 'main' },
        mocks: { $route: { params: { path: deepPath } } },
      });

      await waitForPromises();
      expect(getQueryHandlerSuccess).toHaveBeenCalledTimes(2); // root + dir_0
    });

    it('expands path ancestors when route changes', async () => {
      const treeNode = mockResponse.data.project.repository.paginatedTree.nodes[0];
      const response = cloneDeep(mockResponse);
      response.data.project.repository.paginatedTree.nodes[0].trees.nodes = [
        { ...treeNode.trees.nodes[0], name: 'test_dir', path: 'test_dir', flatPath: 'test_dir' },
      ];

      getQueryHandlerSuccess = jest.fn().mockResolvedValueOnce(response);

      const route = Vue.observable({ params: {} });
      wrapper = shallowMountExtended(TreeList, {
        apolloProvider: createMockApollo([[paginatedTreeQuery, getQueryHandlerSuccess]]),
        pinia,
        propsData: { projectPath: 'group/project', currentRef: 'main' },
        mocks: { $router: { push: jest.fn() }, $route: route },
      });
      await waitForPromises();

      route.params = { path: 'test_dir/file.txt' };
      await nextTick();
      await waitForPromises();

      expect(getQueryHandlerSuccess).toHaveBeenCalledWith(
        expect.objectContaining({ path: 'test_dir' }),
      );
    });
  });

  describe('keyboard navigation', () => {
    const mockDir = (items = []) => {
      const response = cloneDeep(mockResponse);
      response.data.project.repository.paginatedTree.nodes[0].trees.nodes = items.filter(
        (i) => !i.sha,
      );
      response.data.project.repository.paginatedTree.nodes[0].blobs.nodes = items.filter(
        (i) => i.sha,
      );
      return response;
    };

    it.each([
      ['ArrowDown', 1],
      ['ArrowUp', 0],
    ])('moves focus with %s key', async (key, expectedIndex) => {
      await createComponent();
      await nextTick();

      const items = findTreeItems();
      findTree().trigger('keydown', { key });
      await nextTick();

      expect(items.at(expectedIndex).attributes('tabindex')).toBe('0');
    });

    it.each(['Enter', ' '])('expands directory with %s key', async (key) => {
      await createComponent();

      const subdirResponse = cloneDeep(mockResponse);
      subdirResponse.data.project.repository.paginatedTree.nodes[0].trees.nodes = [];
      subdirResponse.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [];
      getQueryHandlerSuccess.mockResolvedValueOnce(subdirResponse);

      findTree().trigger('keydown', { key }); // Trigger keyboard
      await waitForPromises();

      expect(getQueryHandlerSuccess).toHaveBeenLastCalledWith(
        expect.objectContaining({ path: 'dir_1/dir_2' }),
      );
    });

    it.each(['Enter', ' '])('triggers show more with %s key', async (key) => {
      const paginatedResponse = cloneDeep(mockResponse);
      paginatedResponse.data.project.repository.paginatedTree.pageInfo.hasNextPage = true;
      await createComponent(paginatedResponse);

      const secondPageResponse = cloneDeep(mockResponse);
      secondPageResponse.data.project.repository.paginatedTree.nodes[0].trees.nodes = [];
      secondPageResponse.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [];
      getQueryHandlerSuccess.mockResolvedValueOnce(secondPageResponse);

      findTree().trigger('keydown', { key: 'ArrowDown' });
      findTree().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();

      findTree().trigger('keydown', { key, preventDefault: jest.fn() });
      await waitForPromises();

      expect(getQueryHandlerSuccess).toHaveBeenLastCalledWith(
        expect.objectContaining({ nextPageCursor: 'cursor123' }),
      );
    });

    it.each(['Enter', ' '])('navigates to file with %s key', async (key) => {
      await createComponent();
      await nextTick();

      findTree().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();

      findTree().trigger('keydown', { key });
      await nextTick();

      expect(wrapper.vm.$router.push).toHaveBeenCalledWith(
        '/-/blob/main/dir_1/file.txt?ref_type=heads',
      );
    });

    it('does not move focus beyond list boundaries', async () => {
      await createComponent();
      await nextTick();

      const items = findTreeItems();

      findTree().trigger('keydown', { key: 'ArrowUp' });
      await nextTick();
      expect(items.at(0).attributes('tabindex')).toBe('0');

      findTree().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();
      findTree().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();

      expect(items.at(1).attributes('tabindex')).toBe('0');
    });

    it.each([
      ['Home', 'dir_2'],
      ['End', 'file.txt'],
    ])('moves focus to %s item with %s key', async (key, expectedName) => {
      await createComponent();

      findTree().trigger('keydown', { key });
      await nextTick();

      const items = findTreeItems();
      const focusedItem = items.wrappers.find((item) => item.attributes('tabindex') === '0');
      const fileRow = focusedItem.findComponent(FileRow);
      expect(fileRow.props('file').name).toBe(expectedName);
    });

    it('expands sibling directories at same level with * key', async () => {
      const response = cloneDeep(mockResponse);
      const treeNode = response.data.project.repository.paginatedTree.nodes[0];
      const baseTree = treeNode.trees.nodes[0];
      treeNode.trees.nodes = [
        {
          ...baseTree,
          id: 'gid://gitlab/Tree/1',
          name: 'dir_1',
          path: 'dir_1',
          flatPath: 'dir_1',
          webPath: '/dir_1',
        },
        {
          ...baseTree,
          id: 'gid://gitlab/Tree/2',
          name: 'dir_2',
          path: 'dir_2',
          flatPath: 'dir_2',
          webPath: '/dir_2',
        },
      ];
      treeNode.blobs.nodes = [];
      await createComponent(response);

      const emptyResponse = cloneDeep(mockResponse);
      emptyResponse.data.project.repository.paginatedTree.nodes[0].trees.nodes = [];
      emptyResponse.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [];
      getQueryHandlerSuccess.mockResolvedValue(emptyResponse);

      findTree().trigger('keydown', { key: '*' });
      await waitForPromises();

      const fileRows = findFileRows();
      expect(fileRows.at(0).props('file').opened).toBe(true);
      expect(fileRows.at(1).props('file').opened).toBe(true);
      expect(findTreeItems().at(0).attributes('tabindex')).toBe('0');
    });

    describe('ArrowRight', () => {
      it('opens closed node', async () => {
        await createComponent();
        getQueryHandlerSuccess.mockResolvedValueOnce(mockDir());
        findTree().trigger('keydown', { key: 'ArrowRight' });
        await waitForPromises();

        expect(findFileRows().at(0).props('file').opened).toBe(true);
      });

      it('moves to first child on open node', async () => {
        await createComponent();
        getQueryHandlerSuccess.mockResolvedValueOnce(
          mockDir([
            { id: 'gid://child', name: 'child_dir', path: 'dir_1/dir_2/child_dir', webPath: '...' },
          ]),
        );
        findTree().trigger('keydown', { key: 'ArrowRight' });
        await waitForPromises();
        triggerIntersectionForAll();
        await nextTick();

        findTree().trigger('keydown', { key: 'ArrowRight' });
        await nextTick();

        expect(findTreeItems().at(1).attributes('tabindex')).toBe('0');
      });

      it('does nothing on end node', async () => {
        await createComponent();
        findTree().trigger('keydown', { key: 'ArrowDown' });
        findTree().trigger('keydown', { key: 'ArrowRight' });
        await nextTick();

        expect(findTreeItems().at(1).attributes('tabindex')).toBe('0');
      });
    });

    describe('ArrowLeft', () => {
      it('closes open node', async () => {
        await createComponent();
        getQueryHandlerSuccess.mockResolvedValueOnce(mockDir());
        findTree().trigger('keydown', { key: 'ArrowRight' });
        await waitForPromises();

        findTree().trigger('keydown', { key: 'ArrowLeft' });
        await nextTick();

        expect(findFileRows().at(0).props('file').opened).toBe(false);
      });

      it('moves to parent from child node', async () => {
        await createComponent();
        getQueryHandlerSuccess.mockResolvedValueOnce(
          mockDir([
            { id: 'gid://child', name: 'child_dir', path: 'dir_1/dir_2/child_dir', webPath: '...' },
          ]),
        );
        findTree().trigger('keydown', { key: 'ArrowRight' });
        await waitForPromises();
        triggerIntersectionForAll();
        await nextTick();

        findTree().trigger('keydown', { key: 'ArrowRight' });
        await nextTick();

        expect(findTreeItems().at(1).attributes('tabindex')).toBe('0'); // Verify we're on child

        findTree().trigger('keydown', { key: 'ArrowLeft' });
        await nextTick();

        expect(findTreeItems().at(0).attributes('tabindex')).toBe('0'); // Should be back on parent
      });

      it('does nothing on root node', async () => {
        await createComponent();
        findTree().trigger('keydown', { key: 'ArrowLeft' });
        await nextTick();

        expect(findTreeItems().at(0).attributes('tabindex')).toBe('0');
      });
    });

    describe('letter navigation', () => {
      it.each([
        ['f', 'file.txt', 'moves to next match'],
        ['F', 'file.txt', 'is case-insensitive'],
      ])('pressing "%s" %s', async (key, expectedName) => {
        await createComponent();

        findTree().trigger('keydown', { key });
        await nextTick();

        const focusedItem = findTreeItems().wrappers.find((w) => w.attributes('tabindex') === '0');
        expect(focusedItem.findComponent(FileRow).props('file').name).toBe(expectedName);
      });

      it('wraps around to find match from beginning', async () => {
        await createComponent();

        findTree().trigger('keydown', { key: 'ArrowDown' });
        await nextTick();
        findTree().trigger('keydown', { key: 'd' });
        await nextTick();

        const focusedItem = findTreeItems().wrappers.find((w) => w.attributes('tabindex') === '0');
        expect(focusedItem.findComponent(FileRow).props('file').name).toBe('dir_2');
      });
    });
  });

  describe('Tree toggle', () => {
    it('passes show-tree-toggle="true" prop to all FileRow components', () => {
      findFileRows().wrappers.forEach((fileRow) =>
        expect(fileRow.props('showTreeToggle')).toBe(true),
      );
    });

    it('fetches directory contents when chevron is clicked', async () => {
      const subdirResponse = cloneDeep(mockResponse);
      subdirResponse.data.project.repository.paginatedTree.nodes[0].blobs.nodes = [
        {
          id: 'gid://file1',
          name: 'subfile.txt',
          path: 'dir_1/dir_2/subfile.txt',
          sha: 'xyz789',
          webPath: 'dir_1/dir_2/subfile.txt',
        },
      ];
      getQueryHandlerSuccess.mockResolvedValueOnce(subdirResponse);

      const treeFileRow = findFileRows().at(0); // First row is the tree based on mockResponse
      treeFileRow.vm.$emit('clickTree', treeFileRow.props('file').path);

      await waitForPromises();

      expect(getQueryHandlerSuccess).toHaveBeenLastCalledWith(
        expect.objectContaining({ path: 'dir_1/dir_2' }),
      );
    });
  });

  describe('intersection observer', () => {
    it('renders placeholders before intersection and FileRows after', async () => {
      getQueryHandlerSuccess = jest.fn().mockResolvedValue(mockResponse);
      apolloProvider = createMockApollo([[paginatedTreeQuery, getQueryHandlerSuccess]]);

      wrapper = shallowMountExtended(TreeList, {
        apolloProvider,
        pinia,
        propsData: { projectPath: 'group/project', currentRef: 'main', refType: 'branch' },
        mocks: { $route: { params: {} } },
      });

      await waitForPromises();
      await nextTick();

      // Before intersection: placeholders only
      expect(findFileRowPlaceholders()).toHaveLength(2);
      expect(findFileRows()).toHaveLength(0);

      // After intersection: FileRows rendered
      triggerIntersectionForAll();
      await nextTick();

      expect(findFileRows()).toHaveLength(2);
      expect(findFileRowPlaceholders()).toHaveLength(0);
    });
  });

  describe('special character encoding', () => {
    it('correctly encodes special characters in file paths', async () => {
      const specialCharResponse = cloneDeep(mockResponse);
      specialCharResponse.data.project.repository.paginatedTree.nodes[0].blobs.nodes.push({
        __typename: 'Blob',
        id: 'gid://special',
        sha: 'xyz789',
        name: 'file with spaces & special#chars.txt',
        path: 'dir_1/file with spaces & special#chars.txt',
        mode: '100644',
        webPath: '/dir_1/file with spaces & special#chars.txt',
        flatPath: 'dir_1/file with spaces & special#chars.txt',
        type: 'text',
        lfsOid: null,
      });

      await createComponent(specialCharResponse);

      const fileRows = findFileRows();
      expect(fileRows.at(2).props('file')).toMatchObject({
        name: 'file with spaces & special#chars.txt',
        path: '/dir_1/file with spaces & special#chars.txt',
        routerPath:
          '/-/blob/main/dir_1/file%20with%20spaces%20%26%20special%23chars.txt?ref_type=heads',
      });
    });

    it('correctly encodes special characters in directory paths', async () => {
      const specialCharResponse = cloneDeep(mockResponse);
      specialCharResponse.data.project.repository.paginatedTree.nodes[0].trees.nodes.push({
        __typename: 'TreeEntry',
        id: 'gid://special-dir',
        sha: 'def456',
        name: 'dir with spaces & special#chars',
        path: 'dir_1/dir with spaces & special#chars',
        flatPath: 'dir_1/dir with spaces & special#chars',
        type: 'tree',
        webPath: '/root/jerasmus-test-project/-/tree/master/dir_1/dir with spaces & special#chars',
      });

      await createComponent(specialCharResponse);

      expect(findFileRows().at(1).props('file')).toMatchObject({
        name: 'dir with spaces & special#chars',
        path: '/dir_1/dir with spaces & special#chars',
        routerPath: '/-/tree/main/dir_1/dir%20with%20spaces%20%26%20special%23chars?ref_type=heads',
      });
    });
  });

  describe('ref_type preservation in URLs', () => {
    it('includes ref_type in router paths when refType prop is provided', async () => {
      await createComponent();

      const fileRows = findFileRows();

      expect(fileRows.at(0).props('file').routerPath).toBe(
        '/-/tree/main/dir_1/dir_2?ref_type=heads',
      );
      expect(fileRows.at(1).props('file').routerPath).toBe(
        '/-/blob/main/dir_1/file.txt?ref_type=heads',
      );
    });

    it('excludes ref_type when refType prop is empty', async () => {
      await createComponent(mockResponse, { propsData: { refType: '' } });

      const fileRows = findFileRows();

      expect(fileRows.at(0).props('file').routerPath).toBe('/-/tree/main/dir_1/dir_2');
      expect(fileRows.at(1).props('file').routerPath).toBe('/-/blob/main/dir_1/file.txt');
    });
  });

  describe('submodule handling', () => {
    const webUrl = 'https://example.com/submodule-project';
    beforeEach(async () => {
      const response = cloneDeep(mockResponse);
      response.data.project.repository.paginatedTree.nodes[0].submodules.nodes.push({
        __typename: 'Submodule',
        id: 'gid://Submodule123',
        sha: '1234567890abcdef',
        name: 'submodule-project',
        flatPath: 'submodule-project',
        type: 'commit',
        path: 'submodule-project',
        treeUrl: webUrl,
        webUrl,
      });

      await createComponent(response);
    });

    it('renders submodules with correct properties', () => {
      expect(findFileRows().at(1).props('file')).toMatchObject({ webUrl, submodule: true });
    });

    it('navigates to submodule when clicked', () => {
      findFileRows().at(1).vm.$emit('clickSubmodule', webUrl);

      expect(visitUrl).toHaveBeenCalledWith(webUrl);
    });

    it.each(['Enter', ' '])('navigates to submodule with %s key', async (key) => {
      findTree().trigger('keydown', { key: 'ArrowDown' });
      await nextTick();
      findTree().trigger('keydown', { key });

      expect(visitUrl).toHaveBeenCalledWith(webUrl);
    });

    it('sorts content in correct order: directories, submodules, then files', () => {
      const fileRows = findFileRows();

      expect(fileRows.at(0).props('file').path).toBe('/dir_1/dir_2');
      expect(fileRows.at(1).props('file').path).toBe('/submodule-project');
      expect(fileRows.at(2).props('file').path).toBe('/dir_1/file.txt');
    });
  });
});
