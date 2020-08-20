import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import TreeList from '~/diffs/components/tree_list.vue';
import createStore from '~/diffs/store/modules';

describe('Diffs tree list component', () => {
  let wrapper;
  const getFileRows = () => wrapper.findAll('.file-row');
  const localVue = createLocalVue();
  localVue.use(Vuex);

  const createComponent = state => {
    const store = new Vuex.Store({
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
      ...state,
    };

    wrapper = mount(TreeList, {
      store,
      localVue,
      propsData: { hideFileStats: false },
    });
  };

  beforeEach(() => {
    localStorage.removeItem('mr_diff_tree_list');

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders empty text', () => {
    expect(wrapper.text()).toContain('No files found');
  });

  describe('with files', () => {
    beforeEach(() => {
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

      createComponent({
        treeEntries,
        tree: [treeEntries['index.js'], treeEntries.app],
      });

      return wrapper.vm.$nextTick();
    });

    it('renders tree', () => {
      expect(getFileRows()).toHaveLength(2);
      expect(
        getFileRows()
          .at(0)
          .text(),
      ).toContain('index.js');
      expect(
        getFileRows()
          .at(1)
          .text(),
      ).toContain('app');
    });

    it('hides file stats', () => {
      wrapper.setProps({ hideFileStats: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.file-row-stats').exists()).toBe(false);
      });
    });

    it('calls toggleTreeOpen when clicking folder', () => {
      jest.spyOn(wrapper.vm.$store, 'dispatch').mockReturnValue(undefined);

      getFileRows()
        .at(1)
        .trigger('click');

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
        expect(wrapper.find('.file-row').text()).toContain('index.js');
      });
    });
  });
});
