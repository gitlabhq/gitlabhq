import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { viewerTypes } from '~/ide/constants';
import IdeTree from '~/ide/components/ide_tree.vue';
import { createStoreOptions } from '~/ide/stores';
import { file } from '../helpers';
import { projectData } from '../mock_data';

Vue.use(Vuex);

describe('IdeTree', () => {
  let store;
  let wrapper;

  const actionSpies = {
    updateViewer: jest.fn(),
  };

  const testState = {
    currentProjectId: 'abcproject',
    currentBranchId: 'main',
    projects: {
      abcproject: { ...projectData },
    },
    trees: {
      'abcproject/main': {
        tree: [file('fileName')],
        loading: false,
      },
    },
  };

  const createComponent = (replaceState) => {
    const defaultStore = createStoreOptions();

    store = new Vuex.Store({
      ...defaultStore,
      state: {
        ...defaultStore.state,
        ...testState,
        replaceState,
      },
      actions: {
        ...defaultStore.actions,
        ...actionSpies,
      },
    });

    wrapper = mount(IdeTree, {
      store,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    actionSpies.updateViewer.mockClear();
  });

  describe('renders properly', () => {
    it('renders list of files', () => {
      expect(wrapper.text()).toContain('fileName');
    });
  });

  describe('activated', () => {
    beforeEach(() => {
      createComponent({
        viewer: viewerTypes.diff,
      });
    });

    it('re initializes the component', () => {
      expect(actionSpies.updateViewer).toHaveBeenCalled();
    });

    it('updates viewer to "editor" by default', () => {
      expect(actionSpies.updateViewer).toHaveBeenCalledWith(expect.any(Object), viewerTypes.edit);
    });
  });
});
