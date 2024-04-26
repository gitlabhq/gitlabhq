import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import TreeList from '~/diffs/components/tree_list.vue';
import createStore from '~/diffs/store/modules';
import DiffFileRow from '~/diffs/components//diff_file_row.vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { SET_PINNED_FILE_HASH, SET_TREE_DATA, SET_DIFF_FILES } from '~/diffs/store/mutation_types';
import { generateTreeList } from '~/diffs/utils/tree_worker_utils';
import { sortTree } from '~/ide/stores/utils';

describe('Diffs tree list component', () => {
  let wrapper;
  let store;
  let setRenderTreeListMock;
  const getScroller = () => wrapper.findComponent({ name: 'RecycleScroller' });
  const getFileRow = () => wrapper.findComponent(DiffFileRow);
  const findDiffTreeSearch = () => wrapper.findByTestId('diff-tree-search');

  Vue.use(Vuex);

  const createComponent = ({ hideFileStats = false } = {}) => {
    wrapper = shallowMountExtended(TreeList, {
      store,
      propsData: { hideFileStats },
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
            template: '<div><slot :item="{ tree: [] }"></slot></div>',
          },
        ),
      },
    });
  };

  beforeEach(() => {
    const { getters, mutations, actions, state } = createStore();

    setRenderTreeListMock = jest.fn();

    store = new Vuex.Store({
      modules: {
        diffs: {
          namespaced: true,
          state: {
            isTreeLoaded: true,
            diffFiles: ['test'],
            addedLines: 10,
            removedLines: 20,
            mergeRequestDiff: {},
            realSize: 20,
            ...state,
          },
          getters: {
            allBlobs: getters.allBlobs,
            flatBlobsList: getters.flatBlobsList,
            pinnedFile: getters.pinnedFile,
          },
          mutations: { ...mutations },
          actions: {
            toggleTreeOpen: actions.toggleTreeOpen,
            goToFile: actions.goToFile,
            setRenderTreeList: setRenderTreeListMock,
          },
        },
      },
    });
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
        fileHash: 'test',
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

    Object.assign(store.state.diffs, {
      treeEntries,
      tree: [
        treeEntries.LICENSE,
        {
          ...treeEntries.app,
          tree: [treeEntries['index.js'], treeEntries['test.rb']],
        },
      ],
    });

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
      expect(getScroller().props('items')).toHaveLength(4);
    });

    it('hides file stats', () => {
      createComponent({ hideFileStats: true });
      expect(getFileRow().props('hideFileStats')).toBe(true);
    });

    it('calls toggleTreeOpen when clicking folder', () => {
      jest.spyOn(store, 'dispatch').mockReturnValue(undefined);

      getFileRow().vm.$emit('toggleTreeOpen', 'app');

      expect(store.dispatch).toHaveBeenCalledWith('diffs/toggleTreeOpen', 'app');
    });

    it('renders when renderTreeList is false', async () => {
      store.state.diffs.renderTreeList = false;

      await nextTick();
      expect(getScroller().props('items')).toHaveLength(5);
    });
  });

  describe('with viewedDiffFileIds', () => {
    const viewedDiffFileIds = { fileId: '#12345' };

    beforeEach(() => {
      setupFilesInState();
      store.state.diffs.viewedDiffFileIds = viewedDiffFileIds;
    });

    it('passes the viewedDiffFileIds to the FileTree', async () => {
      createComponent();

      await nextTick();
      expect(getFileRow().props('viewedFiles')).toBe(viewedDiffFileIds);
    });
  });

  describe('pinned file', () => {
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

    const pinFile = (fileHash) => {
      store.commit(`diffs/${SET_PINNED_FILE_HASH}`, fileHash);
    };

    const setupFiles = (diffFiles) => {
      const { treeEntries, tree } = generateTreeList(diffFiles);
      store.commit(`diffs/${SET_DIFF_FILES}`, diffFiles);
      store.commit(`diffs/${SET_TREE_DATA}`, {
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
      it.each(filePaths.map((path) => path[0]))('pins %s file', async (pinnedFile) => {
        pinFile(pinnedFile);
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
      'calls setRenderTreeListMock with `$renderTreeList` when clicking $toggle clicked',
      ({ toggle, renderTreeList }) => {
        createComponent();

        wrapper.findByTestId(toggle).vm.$emit('click');

        expect(setRenderTreeListMock).toHaveBeenCalledWith(expect.anything(), {
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
        store.state.diffs.renderTreeList = renderTreeList;

        createComponent();

        expect(wrapper.findByTestId(deselectedToggle).props('selected')).toBe(false);
        expect(wrapper.findByTestId(selectedToggle).props('selected')).toBe(true);
      },
    );
  });
});
