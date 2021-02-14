import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import TreeList from '~/diffs/components/tree_list.vue';
import createStore from '~/diffs/store/modules';
import FileTree from '~/vue_shared/components/file_tree.vue';

describe('Diffs tree list component', () => {
  let wrapper;
  let store;
  const getFileRows = () => wrapper.findAll('.file-row');
  const localVue = createLocalVue();
  localVue.use(Vuex);

  const createComponent = (mountFn = mount) => {
    wrapper = mountFn(TreeList, {
      store,
      localVue,
      propsData: { hideFileStats: false },
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

  afterEach(() => {
    wrapper.destroy();
  });

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

    it('renders tree', () => {
      expect(getFileRows()).toHaveLength(2);
      expect(getFileRows().at(0).html()).toContain('index.js');
      expect(getFileRows().at(1).html()).toContain('app');
    });

    it('hides file stats', () => {
      wrapper.setProps({ hideFileStats: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.file-row-stats').exists()).toBe(false);
      });
    });

    it('calls toggleTreeOpen when clicking folder', () => {
      jest.spyOn(wrapper.vm.$store, 'dispatch').mockReturnValue(undefined);

      getFileRows().at(1).trigger('click');

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('diffs/toggleTreeOpen', 'app');
    });

    it('calls scrollToFile when clicking blob', () => {
      jest.spyOn(wrapper.vm.$store, 'dispatch').mockReturnValue(undefined);

      wrapper.find('.file-row').trigger('click');

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('diffs/scrollToFile', 'app/index.js');
    });

    it('renders as file list when renderTreeList is false', () => {
      wrapper.vm.$store.state.diffs.renderTreeList = false;

      return wrapper.vm.$nextTick().then(() => {
        expect(getFileRows()).toHaveLength(1);
      });
    });

    it('renders file paths when renderTreeList is false', () => {
      wrapper.vm.$store.state.diffs.renderTreeList = false;

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.file-row').html()).toContain('index.js');
      });
    });
  });

  describe('with viewedDiffFileIds', () => {
    const viewedDiffFileIds = { fileId: '#12345' };

    beforeEach(() => {
      setupFilesInState();
      store.state.diffs.viewedDiffFileIds = viewedDiffFileIds;
    });

    it('passes the viewedDiffFileIds to the FileTree', () => {
      createComponent(shallowMount);

      return wrapper.vm.$nextTick().then(() => {
        // Have to use $attrs['viewed-files'] because we are passing down an object
        // and attributes('') stringifies values (e.g. [object])...
        expect(wrapper.find(FileTree).vm.$attrs['viewed-files']).toBe(viewedDiffFileIds);
      });
    });
  });
});
