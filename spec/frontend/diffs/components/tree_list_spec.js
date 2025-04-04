import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import TreeList from '~/diffs/components/tree_list.vue';
import DiffFileRow from '~/diffs/components//diff_file_row.vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { SET_LINKED_FILE_HASH, SET_TREE_DATA, SET_DIFF_FILES } from '~/diffs/store/mutation_types';
import { generateTreeList } from '~/diffs/utils/tree_worker_utils';
import { sortTree } from '~/ide/stores/utils';
import { isElementClipped } from '~/lib/utils/common_utils';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';

jest.mock('~/lib/utils/common_utils');

Vue.use(PiniaVuePlugin);

describe('Diffs tree list component', () => {
  let wrapper;
  let pinia;
  const getScroller = () => wrapper.findComponent({ name: 'RecycleScroller' });
  const getFileRow = () => wrapper.findComponent(DiffFileRow);
  const findDiffTreeSearch = () => wrapper.findByTestId('diff-tree-search');

  const createComponent = ({ hideFileStats = false, ...rest } = {}) => {
    wrapper = shallowMountExtended(TreeList, {
      pinia,
      propsData: { hideFileStats, ...rest },
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
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin], stubActions: false });
    useLegacyDiffs().isTreeLoaded = true;
    useLegacyDiffs().diffFiles = [getDiffFileMock()];
    useLegacyDiffs().addedLines = 10;
    useLegacyDiffs().addedLines = 20;
    useLegacyDiffs().mergeRequestDiff = {};
    useLegacyDiffs().realSize = '20';
    useLegacyDiffs().setTreeOpen.mockReturnValue();
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

    useLegacyDiffs().treeEntries = treeEntries;
    useLegacyDiffs().tree = [
      treeEntries.LICENSE,
      {
        ...treeEntries.app,
        tree: [treeEntries.javascript, treeEntries['index.js'], treeEntries['test.rb']],
      },
    ];

    return treeEntries;
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty text', () => {
      expect(wrapper.text()).toContain('No files found');
    });
  });

  it('renders file count', () => {
    createComponent();

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
        ${'*.js, *.rb'} | ${3}
      `('returns $itemSize item for $extension', async ({ extension, itemSize }) => {
        const input = findDiffTreeSearch();

        input.vm.$emit('input', extension);

        await nextTick();

        expect(getScroller().props('items')).toHaveLength(itemSize);
      });
    });

    it('renders tree', () => {
      expect(getScroller().props('items')).toHaveLength(6);
    });

    it('re-emits clickFile event', () => {
      const obj = {};
      wrapper.findComponent(DiffFileRow).vm.$emit('clickFile', obj);
      expect(wrapper.emitted('clickFile')).toStrictEqual([[obj]]);
    });

    it('hides file stats', () => {
      createComponent({ hideFileStats: true });
      expect(getFileRow().props('hideFileStats')).toBe(true);
    });

    it('calls toggleTreeOpen when clicking folder', () => {
      getFileRow().vm.$emit('toggleTreeOpen', 'app');

      expect(useLegacyDiffs().toggleTreeOpen).toHaveBeenCalledWith('app');
    });

    it('renders when renderTreeList is false', async () => {
      useLegacyDiffs().renderTreeList = false;

      await nextTick();
      expect(getScroller().props('items')).toHaveLength(5);
    });

    it('dispatches setTreeOpen with all paths for the current diff file', async () => {
      useLegacyDiffs().currentDiffFileId = 'appjavascriptfile';

      await nextTick();

      expect(useLegacyDiffs().setTreeOpen).toHaveBeenCalledWith({
        opened: true,
        path: 'app',
      });
      expect(useLegacyDiffs().setTreeOpen).toHaveBeenCalledWith({
        opened: true,
        path: 'app/javascript',
      });
    });
  });

  describe('with viewedDiffFileIds', () => {
    const viewedDiffFileIds = { fileId: '#12345' };

    beforeEach(() => {
      setupFilesInState();
      useLegacyDiffs().viewedDiffFileIds = viewedDiffFileIds;
    });

    it('passes the viewedDiffFileIds to the FileTree', async () => {
      createComponent();

      await nextTick();
      expect(getFileRow().props('viewedFiles')).toBe(viewedDiffFileIds);
    });
  });

  describe('diff tree set current file auto scoll', () => {
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
      const { treeEntries, tree } = generateTreeList(diffFiles);
      useLegacyDiffs()[SET_TREE_DATA]({
        treeEntries,
        tree: sortTree(tree),
      });
    };

    beforeEach(() => {
      createComponent();
      setupFiles(filePaths.map(([name, path]) => createFile(name, path)));
    });

    it('auto scroll', async () => {
      wrapper.element.insertAdjacentHTML('afterbegin', `<div data-file-row="05.txt"><div>`);
      isElementClipped.mockReturnValueOnce(true);
      wrapper.vm.$refs.scroller.scrollToItem = jest.fn();
      useLegacyDiffs().currentDiffFileId = '05.txt';
      await nextTick();

      expect(wrapper.vm.currentDiffFileId).toBe('05.txt');
      expect(wrapper.vm.$refs.scroller.scrollToItem).toHaveBeenCalledWith(5);
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

    const linkFile = (fileHash) => {
      useLegacyDiffs()[SET_LINKED_FILE_HASH](fileHash);
    };

    const setupFiles = (diffFiles) => {
      const { treeEntries, tree } = generateTreeList(diffFiles);
      useLegacyDiffs()[SET_DIFF_FILES](diffFiles);
      useLegacyDiffs()[SET_TREE_DATA]({
        treeEntries,
        tree: sortTree(tree),
      });
    };

    const createFile = (name, path = '') => ({
      file_hash: name,
      path: `${path}${name}`,
      new_path: `${path}${name}`,
      file_path: `${path}${name}`,
    });

    beforeEach(() => {
      createComponent();
      setupFiles(filePaths.map(([name, path]) => createFile(name, path)));
    });

    describe('files in folders', () => {
      it.each(filePaths.map((path) => path[0]))('links %s file', async (linkedFile) => {
        linkFile(linkedFile);
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
      });
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

        expect(useLegacyDiffs().setRenderTreeList).toHaveBeenCalledWith({
          renderTreeList,
        });
      },
    );

    it.each`
      selectedToggle        | deselectedToggle      | renderTreeList
      ${'list-view-toggle'} | ${'tree-view-toggle'} | ${false}
      ${'tree-view-toggle'} | ${'list-view-toggle'} | ${true}
    `(
      'sets $selectedToggle as selected when renderTreeList is $renderTreeList',
      ({ selectedToggle, deselectedToggle, renderTreeList }) => {
        useLegacyDiffs().renderTreeList = renderTreeList;

        createComponent();

        expect(wrapper.findByTestId(deselectedToggle).props('selected')).toBe(false);
        expect(wrapper.findByTestId(selectedToggle).props('selected')).toBe(true);
      },
    );
  });

  describe('loading state', () => {
    const getLoadedFiles = (offset = 1) =>
      useLegacyDiffs()
        .tree.slice(offset)
        .reduce((acc, el) => {
          acc[el.fileHash] = true;
          return acc;
        }, {});

    beforeEach(() => {
      setupFilesInState();
    });

    it('sets loading state for loading files', () => {
      const loadedFiles = getLoadedFiles();
      createComponent({ loadedFiles });
      const [firstItem, secondItem] = getScroller().props('items');
      expect(firstItem.loading).toBe(true);
      expect(secondItem.loading).toBe(false);
    });

    it('is not focusable', () => {
      const loadedFiles = getLoadedFiles();
      createComponent({ loadedFiles });
      expect(wrapper.findAllComponents(DiffFileRow).at(0).attributes('tabindex')).toBe('-1');
    });

    it('ignores clicks on loading files', () => {
      const loadedFiles = getLoadedFiles();
      createComponent({ loadedFiles });
      wrapper.findAllComponents(DiffFileRow).at(0).vm.$emit('clickFile', {});
      expect(wrapper.emitted('clickFile')).toBe(undefined);
    });
  });
});
