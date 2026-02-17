import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import TreeList from '~/diffs/components/tree_list.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useCodeReview } from '~/diffs/stores/code_review';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { isElementClipped } from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils');

Vue.use(PiniaVuePlugin);

describe('Diffs tree list component', () => {
  let wrapper;
  let pinia;
  const getScroller = () => wrapper.findComponent({ name: 'RecycleScroller' });
  const findDiffTreeSearch = () => wrapper.findByTestId('diff-tree-search');

  const createComponent = ({ hideFileStats = false, ...rest } = {}, { stubs } = {}) => {
    wrapper = shallowMountExtended(TreeList, {
      pinia,
      propsData: { hideFileStats, rowHeight: 30, ...rest },
      stubs: {
        // eslint will fail if we import the real component
        RecycleScroller: stubComponent(
          {
            name: 'RecycleScroller',
            props: {
              items: null,
            },
          },
          {
            template:
              '<div><template v-for="item in items"><slot :item="item"></slot></template></div>',
          },
        ),
        ...stubs,
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin], stubActions: false });
    useFileBrowser();
    useCodeReview();
  });

  const setupFilesInState = () => {
    const treeEntries = {
      app: {
        key: 'app',
        path: 'app',
        name: 'app',
        type: 'tree',
        tree: [],
        opened: true,
      },
      javascript: {
        key: 'appjavascript',
        path: 'app/javascript',
        name: 'javascript',
        type: 'tree',
        tree: [
          {
            addedLines: 0,
            changed: true,
            deleted: false,
            fileHash: 'appjavascriptfile',
            key: 'file.js',
            name: 'file.js',
            path: 'app/javascript/file.rb',
            removedLines: 0,
            tempFile: true,
            type: 'blob',
            parentPath: 'app/javascript',
            tree: [],
            file_path: 'app/javascript/file.js',
            file_hash: 'appjavascriptfile',
          },
        ],
        opened: true,
      },
      'index.js': {
        addedLines: 0,
        changed: true,
        deleted: false,
        fileHash: 'test',
        key: 'index.js',
        name: 'index.js',
        path: 'app/index.js',
        removedLines: 0,
        tempFile: true,
        type: 'blob',
        parentPath: 'app',
        tree: [],
        file_path: 'app/index.js',
        file_hash: 'app-index',
        codeReviewId: 12345,
      },
      'unordered.rb': {
        addedLines: 0,
        changed: true,
        deleted: false,
        fileHash: 'unordered',
        key: 'unordered.rb',
        name: 'unordered.rb',
        path: 'unordered.rb',
        removedLines: 0,
        tempFile: true,
        type: 'blob',
        parentPath: '/',
        tree: [],
        file_path: 'unordered.rb',
        file_hash: 'unordered',
      },
      'test.rb': {
        addedLines: 0,
        changed: true,
        deleted: false,
        fileHash: 'apptest',
        key: 'test.rb',
        name: 'test.rb',
        path: 'app/test.rb',
        removedLines: 0,
        tempFile: true,
        type: 'blob',
        parentPath: 'app',
        tree: [],
        file_path: 'app/test.rb',
        file_hash: 'app-test',
      },
      LICENSE: {
        addedLines: 0,
        changed: true,
        deleted: false,
        fileHash: 'LICENSE',
        key: 'LICENSE',
        name: 'LICENSE',
        path: 'LICENSE',
        removedLines: 0,
        tempFile: true,
        type: 'blob',
        parentPath: '/',
        tree: [],
        file_path: 'LICENSE',
        file_hash: 'LICENSE',
      },
    };

    useFileBrowser().treeEntries = treeEntries;
    useFileBrowser().tree = [
      {
        ...treeEntries.app,
        tree: [treeEntries.javascript, treeEntries['index.js'], treeEntries['test.rb']],
      },
      treeEntries['unordered.rb'],
      treeEntries.LICENSE,
    ];

    return treeEntries;
  };

  it('renders empty text', () => {
    createComponent();
    expect(wrapper.text()).toContain('No files found');
  });

  it('renders title', () => {
    createComponent();
    expect(wrapper.find('h2').text()).toContain('Files');
  });

  it('renders file count', () => {
    createComponent({ totalFilesCount: '20' });

    expect(wrapper.findByTestId('file-count').text()).toBe('20');
  });

  describe('with files', () => {
    beforeEach(() => {
      setupFilesInState();
      createComponent();
    });

    describe('search by file extension', () => {
      it('hides scroller for no matches', async () => {
        const input = findDiffTreeSearch();

        input.vm.$emit('input', '*.md');

        await nextTick();

        expect(getScroller().exists()).toBe(false);
        expect(wrapper.text()).toContain('No files found');
      });

      it.each`
        extension       | itemSize
        ${'*.js'}       | ${2}
        ${'index.js'}   | ${2}
        ${'app/*.js'}   | ${2}
        ${'*.js, *.rb'} | ${5}
      `('returns $itemSize item for $extension', async ({ extension, itemSize }) => {
        const input = findDiffTreeSearch();

        input.vm.$emit('input', extension);

        await nextTick();

        expect(getScroller().props('items')).toHaveLength(itemSize);
      });
    });

    it('renders tree', () => {
      expect(
        getScroller()
          .props('items')
          .map((item) => item.path),
      ).toStrictEqual([
        'app',
        'app/javascript',
        'app/javascript/file.rb',
        'app/index.js',
        'app/test.rb',
        'unordered.rb',
        'LICENSE',
      ]);
    });

    it('re-emits clickFile event', () => {
      const row = wrapper.findComponent(FileRow);
      const item = row.props('file');
      row.vm.$emit('clickFile', { stopPropagation: jest.fn() });
      expect(wrapper.emitted('clickFile')).toMatchObject([[item]]);
    });

    it('re-emits clickSubmodule as clickFile event', () => {
      const row = wrapper.findComponent(FileRow);
      const item = row.props('file');
      row.vm.$emit('clickSubmodule', { stopPropagation: jest.fn() });
      expect(wrapper.emitted('clickFile')).toMatchObject([[item]]);
    });

    it('re-emits clickTree event as toggleFolder', () => {
      const row = wrapper.findComponent(FileRow);
      const item = row.props('file');
      row.vm.$emit('clickTree', { stopPropagation: jest.fn() });
      expect(wrapper.emitted('toggleFolder')).toMatchObject([[item.path]]);
    });

    describe('when renderTreeList is false', () => {
      beforeEach(() => {
        useFileBrowser().renderTreeList = false;
      });

      it('renders list items', async () => {
        await nextTick();
        expect(
          getScroller()
            .props('items')
            .map((item) => item.path),
        ).toStrictEqual(['app', 'app/index.js', 'app/test.rb', '/', 'unordered.rb', 'LICENSE']);
      });

      it('renders ungrouped list items', async () => {
        createComponent({ groupBlobsListItems: false });
        await nextTick();
        expect(
          getScroller()
            .props('items')
            .map((item) => item.path),
        ).toStrictEqual([
          'app',
          'app/index.js',
          '/',
          'unordered.rb',
          'app',
          'app/test.rb',
          '/',
          'LICENSE',
        ]);
      });
    });

    it('dispatches setTreeOpen with all paths for the current diff file', async () => {
      const spy = jest.spyOn(useFileBrowser(), 'setTreeOpen').mockReturnValue();
      await wrapper.setProps({ currentDiffFileId: 'appjavascriptfile' });

      expect(spy).toHaveBeenCalledWith('app', true);
      expect(spy).toHaveBeenCalledWith('app/javascript', true);
    });
  });

  describe('with reviewedIds', () => {
    const reviewedIds = { 12345: true };

    beforeEach(() => {
      setupFilesInState();
      useCodeReview().reviewedIds = reviewedIds;
    });

    it('sets viewed property based on reviewedIds', async () => {
      createComponent();

      await nextTick();
      const items = getScroller().props('items');
      const viewedFile = items.find((item) => item.codeReviewId === 12345);
      expect(viewedFile?.viewed).toBe(true);
    });
  });

  describe('diff tree active file scroll', () => {
    const filePaths = [];

    for (let i = 1; i <= 10; i += 1) {
      const fileName = `${i.toString().padStart(2, '0')}.txt`;
      filePaths.push([fileName, 'folder/']);
    }

    const createFile = (name, path = '') => ({
      file_hash: name,
      path: `${path}${name}`,
      new_path: `${path}${name}`,
      file_path: `${path}${name}`,
    });

    const setupFiles = (diffFiles) => {
      useFileBrowser().setTreeData(diffFiles);
    };

    beforeEach(() => {
      setupFiles(filePaths.map(([name, path]) => createFile(name, path)));
    });

    it('scrolls to selected item when item is virtualized', async () => {
      const scrollToItem = jest.fn();
      createComponent(
        { currentDiffFileId: '05.txt' },
        { stubs: { RecycleScroller: { render() {}, methods: { scrollToItem } } } },
      );
      await nextTick();
      jest.runAllTimers();
      expect(scrollToItem).toHaveBeenCalledWith(5);
    });

    it('scrolls clipped item into view', async () => {
      isElementClipped.mockReturnValueOnce(true);
      const spy = jest.spyOn(HTMLElement.prototype, 'scrollIntoView');
      createComponent({ currentDiffFileId: '05.txt' });
      await nextTick();
      jest.runAllTimers();
      expect(spy).toHaveBeenCalledTimes(1);
    });
  });

  describe('linked file', () => {
    const filePaths = [
      ['nested-1.rb', 'folder/sub-folder/'],
      ['nested-2.rb', 'folder/sub-folder/'],
      ['nested-3.rb', 'folder/sub-folder/'],
      ['1.rb', 'folder/'],
      ['2.rb', 'folder/'],
      ['3.rb', 'folder/'],
      ['single.rb', 'folder-single/'],
      ['root-first.rb'],
      ['root-last.rb'],
    ];

    const setupFiles = (diffFiles) => {
      useFileBrowser().setTreeData(diffFiles);
    };

    const createFile = (name, path = '') => ({
      file_hash: name,
      path: `${path}${name}`,
      new_path: `${path}${name}`,
      file_path: `${path}${name}`,
    });

    beforeEach(() => {
      setupFiles(filePaths.map(([name, path]) => createFile(name, path)));
    });

    describe('files in folders', () => {
      it.each(filePaths.map((paths) => paths.toReversed().join('')))(
        'links %s file',
        async (linkedFilePath) => {
          createComponent({ linkedFilePath });
          await nextTick();
          const items = getScroller().props('items');
          expect(
            items.map(
              (item) =>
                `${'─'.repeat(item.level * 2)}${item.type === 'tree' ? '📁' : ''}${
                  item.name || item.path
                }`,
            ),
          ).toMatchSnapshot();
        },
      );
    });
  });

  describe('tree view buttons', () => {
    it.each`
      toggle                | renderTreeList
      ${'list-view-toggle'} | ${false}
      ${'tree-view-toggle'} | ${true}
    `(
      'calls setRenderTreeList with `$renderTreeList` when clicking $toggle clicked',
      ({ toggle, renderTreeList }) => {
        createComponent();

        wrapper.findByTestId(toggle).vm.$emit('click');

        expect(useFileBrowser().setRenderTreeList).toHaveBeenCalledWith(renderTreeList);
      },
    );

    it.each`
      selectedToggle        | deselectedToggle      | renderTreeList
      ${'list-view-toggle'} | ${'tree-view-toggle'} | ${false}
      ${'tree-view-toggle'} | ${'list-view-toggle'} | ${true}
    `(
      'sets $selectedToggle as selected when renderTreeList is $renderTreeList',
      ({ selectedToggle, deselectedToggle, renderTreeList }) => {
        useFileBrowser().renderTreeList = renderTreeList;

        createComponent();

        expect(wrapper.findByTestId(deselectedToggle).props('selected')).toBe(false);
        expect(wrapper.findByTestId(selectedToggle).props('selected')).toBe(true);
      },
    );
  });

  describe('loading state', () => {
    const getLoadingFile = () => useFileBrowser().tree[2];
    const getRootItems = () =>
      getScroller()
        .props('items')
        .filter((item) => item.type !== 'tree');
    const findLoadingItem = (loadedFile) =>
      getRootItems().find((item) => item.type !== 'tree' && item.fileHash !== loadedFile.fileHash);
    const findLoadedItem = (loadedFile) =>
      getRootItems().find((item) => item.type !== 'tree' && item.fileHash === loadedFile.fileHash);

    beforeEach(() => {
      setupFilesInState();
    });

    it('sets loading state for loading files', () => {
      const loadedFile = getLoadingFile();
      createComponent({ loadedFiles: { [loadedFile.fileHash]: true } });
      const loadedItem = findLoadedItem(loadedFile);
      const loadingItem = findLoadingItem(loadedFile);
      expect(loadingItem.loading).toBe(true);
      expect(loadedItem.loading).toBe(false);
    });

    it('is not focusable', () => {
      const loadedFile = getLoadingFile();
      createComponent({ loadedFiles: { [loadedFile.fileHash]: true } });
      const loadingItemIndex = getScroller().props('items').indexOf(findLoadingItem(loadedFile));
      expect(wrapper.findAllComponents(FileRow).at(loadingItemIndex).attributes('tabindex')).toBe(
        '-1',
      );
    });

    it('ignores clicks on loading files', () => {
      const loadedFile = getLoadingFile();
      createComponent({ loadedFiles: { [loadedFile.fileHash]: true } });
      const loadingItemIndex = getScroller().props('items').indexOf(findLoadingItem(loadedFile));
      wrapper.findAllComponents(FileRow).at(loadingItemIndex).vm.$emit('clickFile', {});
      expect(wrapper.emitted('clickFile')).toBe(undefined);
    });
  });
});
