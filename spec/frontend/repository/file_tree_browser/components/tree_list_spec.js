import Vue, { nextTick } from 'vue';
import { GlFormInput, GlIcon, GlTooltip } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { cloneDeep } from 'lodash';
import { PiniaVuePlugin } from 'pinia';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TreeList from '~/repository/file_tree_browser/components/tree_list.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import { FOCUS_FILE_TREE_BROWSER_FILTER_BAR, keysFor } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import { Mousetrap } from '~/lib/mousetrap';
import FileTreeBrowserToggle from '~/repository/file_tree_browser/components/file_tree_browser_toggle.vue';
import * as utils from '~/repository/file_tree_browser/utils';
import { mockResponse } from '../mock_data';

Vue.use(VueApollo);
Vue.use(PiniaVuePlugin);

jest.mock('~/repository/utils/ref_type', () => ({ getRefType: jest.fn(() => 'MOCK_REF_TYPE') }));
jest.mock('~/lib/utils/url_utility', () => ({ joinPaths: jest.fn((...args) => args.join('/')) }));
jest.mock('~/behaviors/shortcuts/shortcuts_toggle');

describe('Tree List', () => {
  let wrapper;
  let apolloProvider;
  let pinia;
  let getQueryHandlerSuccess;

  const createComponent = async (apiResponse = mockResponse) => {
    getQueryHandlerSuccess = jest.fn().mockResolvedValue(apiResponse);

    apolloProvider = createMockApollo([[paginatedTreeQuery, getQueryHandlerSuccess]]);

    wrapper = shallowMountExtended(TreeList, {
      apolloProvider,
      pinia,
      propsData: { projectPath: 'group/project', currentRef: 'main', refType: 'branch' },
      mocks: { $route: { params: {}, $apollo: { query: jest.fn() } } },
    });

    await waitForPromises();
  };

  beforeEach(() => createComponent());

  const findFileTreeToggle = () => wrapper.findComponent(FileTreeBrowserToggle);
  const findTree = () => wrapper.find('[role="tree"]');
  const findHeader = () => wrapper.find('h3');
  const findFileRows = () => wrapper.findAllComponents(FileRow);
  const findFilterInput = () => wrapper.findComponent(GlFormInput);
  const findFilterIcon = () => wrapper.findComponent(GlIcon);
  const findNoFilesMessage = () => wrapper.findByText('No files found');
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
        routerPath: '/-/tree/main//dir_1/dir_2',
        type: 'tree',
      },
      fileUrl: '/-/tree/main//dir_1/dir_2',
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
        routerPath: '/-/blob/main//dir_1/file.txt',
      },
      fileUrl: '/-/blob/main//dir_1/file.txt',
      level: 0,
    });
  });

  it('calls toggleDirectory with correct path when clickTree is emitted from FileRow', () => {
    const toggleDirectory = jest.spyOn(wrapper.vm, 'toggleDirectory').mockImplementation(() => {});
    const path = '/dir_1/dir_2';
    findFileRows().at(0).vm.$emit('clickTree', path);
    expect(toggleDirectory).toHaveBeenCalledWith(path);
  });

  it('sets aria-setsize and aria-posinset relative to siblings at same level', async () => {
    await createComponent();
    const fileRows = findFileRows();

    expect(fileRows.at(0).attributes('aria-setsize')).toBe('2');
    expect(fileRows.at(0).attributes('aria-posinset')).toBe('1');

    expect(fileRows.at(1).attributes('aria-setsize')).toBe('2');
    expect(fileRows.at(1).attributes('aria-posinset')).toBe('2');
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

    it('fetches the next page', () => {
      findFileRows().at(2).vm.$emit('showMore');

      expect(getQueryHandlerSuccess).toHaveBeenCalledWith({
        projectPath: 'group/project',
        ref: 'main',
        refType: 'MOCK_REF_TYPE',
        path: '/',
        nextPageCursor: 'cursor123',
        pageSize: 100,
      });
    });

    it('can filter with Show more button in the list', async () => {
      const filterQuery = '/dir_1/dir_2';
      expect(findFileRows()).toHaveLength(3); // Contains all items before filtering

      findFilterInput().vm.$emit('input', filterQuery);
      await nextTick();

      expect(findFileRows()).toHaveLength(1); // Contains only one item after filtering
      expect(findFileRows().at(0).props('file')).toMatchObject({ path: filterQuery });
    });
  });

  describe('filtering', () => {
    it('renders filter input with icon', () => {
      expect(findFilterInput().exists()).toBe(true);
      expect(findFilterIcon().exists()).toBe(true);
      expect(findFilterIcon().props('name')).toBe('filter');
      expect(findFilterIcon().props('variant')).toBe('subtle');
      expect(findFilterInput().attributes('type')).toBe('search');
    });

    const filterTestCases = [
      { filter: 'file.txt', expectedNames: ['file.txt'] },
      { filter: '*.txt', expectedNames: ['file.txt'] },
      { filter: 'dir_2', expectedNames: ['dir_2'] },
      { filter: '*.nonexistent', expectedNames: [] },
    ];

    it.each(filterTestCases)('filters correctly with "$filter"', ({ filter, expectedNames }) => {
      findFilterInput().vm.$emit('input', filter);
      const fileNames = findFileRows().wrappers.map((row) => row.props('file').name);

      expect(fileNames).toEqual(expect.arrayContaining(expectedNames));
    });
  });

  describe('empty state', () => {
    it('shows no files message when filtered list is empty', async () => {
      findFilterInput().vm.$emit('input', '*.nonexistent');
      await waitForPromises();
      expect(findNoFilesMessage().exists()).toBe(true);
    });
  });

  it('triggers a tracking event when filter bar is click', async () => {
    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

    createComponent();
    findFilterInput().vm.$emit('click', '*.nonexistent');

    await nextTick();

    expect(trackEventSpy).toHaveBeenCalledWith(
      'focus_file_tree_browser_filter_bar_on_repository_page',
      { label: 'click' },
      undefined,
    );
  });

  describe('handles filter bar focus correctly when shortcuts are enabled', () => {
    beforeEach(() => {
      shouldDisableShortcuts.mockReturnValue(false);
      createComponent();
    });

    it('focuses filter input when triggerFocusFilterBar is called', async () => {
      const mockFocus = jest.fn();
      findFilterInput().vm.focus = mockFocus;

      const mousetrapInstance = wrapper.vm.mousetrap;
      mousetrapInstance.trigger('f');

      await nextTick();

      expect(mockFocus).toHaveBeenCalled();
    });

    it('triggers a tracking event when shortcut is used', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      const mockFocus = jest.fn();
      findFilterInput().vm.focus = mockFocus;

      const mousetrapInstance = wrapper.vm.mousetrap;
      mousetrapInstance.trigger('f');

      await nextTick();

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
  });

  describe('handles filter bar focus correctly when shortcuts are disabled', () => {
    beforeEach(() => {
      shouldDisableShortcuts.mockReturnValue(true);
      createComponent();
    });

    it('does not focus when shortcuts are disabled', async () => {
      const mockFocus = jest.fn();
      findFilterInput().vm.focus = mockFocus;

      const mousetrapInstance = wrapper.vm.mousetrap;
      mousetrapInstance.trigger('f');

      await nextTick();

      expect(mockFocus).not.toHaveBeenCalled();
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
  });

  describe('deep path navigation with pagination', () => {
    it('paginates to find directories not on first page', async () => {
      const page1 = cloneDeep(mockResponse);
      page1.data.project.repository.paginatedTree.nodes[0].trees.nodes = [
        { id: 'gid://dir_1', name: 'dir_1', path: 'dir_1', webPath: 'dir_1' },
      ];
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
        page.data.project.repository.paginatedTree.nodes[0].trees.nodes = [
          { id: `gid://dir_${i}`, name: `dir_${i}`, path: `dir_${i}`, webPath: `dir_${i}` },
        ];
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
  });

  describe('keyboard navigation', () => {
    it('calls handleTreeKeydown when keydown is triggered on tree', async () => {
      jest.spyOn(utils, 'handleTreeKeydown');
      await createComponent();

      findTree().trigger('keydown', { key: 'ArrowDown' });

      expect(utils.handleTreeKeydown).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'keydown', key: 'ArrowDown' }),
      );
    });
  });
});
