import Vue from 'vue';
import IdeTree from '~/ide/components/ide_tree.vue';
import { createStore } from '~/ide/stores';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { file } from '../helpers';
import { projectData } from '../mock_data';

describe('IdeRepoTree', () => {
  let store;
  let vm;

  beforeEach(() => {
    store = createStore();

    const IdeRepoTree = Vue.extend(IdeTree);

    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = { ...projectData };
    Vue.set(store.state.trees, 'abcproject/master', {
      tree: [file('fileName')],
      loading: false,
    });

    vm = createComponentWithStore(IdeRepoTree, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders list of files', () => {
    expect(vm.$el.textContent).toContain('fileName');
  });
});
