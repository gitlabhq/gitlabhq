import Vue from 'vue';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import commitSidebarList from '~/ide/components/commit_sidebar/list.vue';
import { createStore } from '~/ide/stores';
import { file } from '../../helpers';

describe('Multi-file editor commit sidebar list', () => {
  let store;
  let vm;

  beforeEach(() => {
    store = createStore();

    const Component = Vue.extend(commitSidebarList);

    vm = createComponentWithStore(Component, store, {
      title: 'Staged',
      fileList: [],
      action: 'stageAllChanges',
      actionBtnText: 'stage all',
      actionBtnIcon: 'history',
      activeFileKey: 'staged-testing',
      keyPrefix: 'staged',
    });

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with a list of files', () => {
    beforeEach((done) => {
      const f = file('file name');
      f.changed = true;
      vm.fileList.push(f);

      Vue.nextTick(done);
    });

    it('renders list', () => {
      expect(vm.$el.querySelectorAll('.multi-file-commit-list > li').length).toBe(1);
    });
  });

  describe('empty files array', () => {
    it('renders no changes text when empty', () => {
      expect(vm.$el.textContent).toContain('No changes');
    });
  });
});
