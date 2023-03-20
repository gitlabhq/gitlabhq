import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { keepAlive } from 'helpers/keep_alive_component_helper';
import IdeTree from '~/ide/components/ide_tree.vue';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';
import { projectData } from '../mock_data';

Vue.use(Vuex);

describe('IdeTree', () => {
  let store;
  let wrapper;

  beforeEach(() => {
    store = createStore();

    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'main';
    store.state.projects.abcproject = { ...projectData };
    Vue.set(store.state.trees, 'abcproject/main', {
      tree: [file('fileName')],
      loading: false,
    });

    wrapper = mount(keepAlive(IdeTree), {
      store,
    });
  });

  it('renders list of files', () => {
    expect(wrapper.text()).toContain('fileName');
  });

  describe('activated', () => {
    let inititializeSpy;

    beforeEach(async () => {
      inititializeSpy = jest.spyOn(wrapper.findComponent(IdeTree).vm, 'initialize');
      store.state.viewer = 'diff';

      await wrapper.vm.reactivate();
    });

    it('re initializes the component', () => {
      expect(inititializeSpy).toHaveBeenCalled();
    });

    it('updates viewer to "editor" by default', () => {
      expect(store.state.viewer).toBe('editor');
    });
  });
});
