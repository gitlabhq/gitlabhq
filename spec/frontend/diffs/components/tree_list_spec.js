import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import TreeList from '~/diffs/components/tree_list.vue';
import createStore from '~/diffs/store/modules';
import DiffFileRow from '~/diffs/components//diff_file_row.vue';
import { stubComponent } from 'helpers/stub_component';

describe('Diffs tree list component', () => {
  let wrapper;
  let store;
  const getScroller = () => wrapper.findComponent({ name: 'RecycleScroller' });
  const getFileRow = () => wrapper.findComponent(DiffFileRow);
  Vue.use(Vuex);

  const createComponent = () => {
    wrapper = shallowMount(TreeList, {
      store,
      propsData: { hideFileStats: false },
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
        wrapper.find('[data-testid="diff-tree-search"]').setValue('*.md');

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
        wrapper.find('[data-testid="diff-tree-search"]').setValue(extension);

        await nextTick();

        expect(getScroller().props('items')).toHaveLength(itemSize);
      });
    });

    it('renders tree', () => {
      expect(getScroller().props('items')).toHaveLength(2);
    });

    it('hides file stats', async () => {
      wrapper.setProps({ hideFileStats: true });

      await nextTick();
      expect(wrapper.find('.file-row-stats').exists()).toBe(false);
    });

    it('calls toggleTreeOpen when clicking folder', () => {
      jest.spyOn(wrapper.vm.$store, 'dispatch').mockReturnValue(undefined);

      getFileRow().vm.$emit('toggleTreeOpen', 'app');

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('diffs/toggleTreeOpen', 'app');
    });

    it('renders when renderTreeList is false', async () => {
      wrapper.vm.$store.state.diffs.renderTreeList = false;

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
      expect(wrapper.findComponent(DiffFileRow).props('viewedFiles')).toBe(viewedDiffFileIds);
    });
  });
});
