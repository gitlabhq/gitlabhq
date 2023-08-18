import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import TreeList from '~/diffs/components/tree_list.vue';
import createStore from '~/diffs/store/modules';
import batchComments from '~/batch_comments/stores/modules/batch_comments';
import DiffFileRow from '~/diffs/components//diff_file_row.vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Diffs tree list component', () => {
  let wrapper;
  let store;
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
    store = new Vuex.Store({
      modules: {
        diffs: createStore(),
        batchComments: batchComments(),
      },
    });

    // Setup initial state
    store.state.diffs.isTreeLoaded = true;
    store.state.diffs.diffFiles.push('test');
    store.state.diffs = {
      addedLines: 10,
      removedLines: 20,
      ...store.state.diffs,
    };
  });

  const setupFilesInState = () => {
    const treeEntries = {
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
      },
      app: {
        key: 'app',
        path: 'app',
        name: 'app',
        type: 'tree',
        tree: [],
      },
    };

    Object.assign(store.state.diffs, {
      treeEntries,
      tree: [treeEntries['index.js'], treeEntries.app],
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty text', () => {
      expect(wrapper.text()).toContain('No files found');
    });
  });

  describe('with files', () => {
    beforeEach(() => {
      setupFilesInState();
      createComponent();
    });

    describe('search by file extension', () => {
      it('hides scroller for no matches', async () => {
        const input = findDiffTreeSearch();

        input.element.value = '*.md';
        input.trigger('input');

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

        input.element.value = extension;
        input.trigger('input');

        await nextTick();

        expect(getScroller().props('items')).toHaveLength(itemSize);
      });
    });

    it('renders tree', () => {
      expect(getScroller().props('items')).toHaveLength(2);
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
      expect(getScroller().props('items')).toHaveLength(3);
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
});
