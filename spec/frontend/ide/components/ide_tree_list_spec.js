import Vue from 'vue';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import IdeTreeList from '~/ide/components/ide_tree_list.vue';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';
import { projectData } from '../mock_data';

describe('IDE tree list', () => {
  const Component = Vue.extend(IdeTreeList);
  const normalBranchTree = [file('fileName')];
  const emptyBranchTree = [];
  let vm;
  let store;

  const bootstrapWithTree = (tree = normalBranchTree) => {
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'main';
    store.state.projects.abcproject = { ...projectData };
    Vue.set(store.state.trees, 'abcproject/main', {
      tree,
      loading: false,
    });

    vm = createComponentWithStore(Component, store, {
      viewerType: 'edit',
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('normal branch', () => {
    beforeEach(() => {
      bootstrapWithTree();

      vm.$mount();
    });

    it('renders loading indicator', (done) => {
      store.state.trees['abcproject/main'].loading = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.multi-file-loading-container')).not.toBeNull();
        expect(vm.$el.querySelectorAll('.multi-file-loading-container').length).toBe(3);

        done();
      });
    });

    it('renders list of files', () => {
      expect(vm.$el.textContent).toContain('fileName');
    });
  });

  describe('empty-branch state', () => {
    beforeEach(() => {
      bootstrapWithTree(emptyBranchTree);

      vm.$mount();
    });

    it('does not load files if the branch is empty', () => {
      expect(vm.$el.textContent).not.toContain('fileName');
      expect(vm.$el.textContent).toContain('No files');
    });
  });
});
