import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import IdeTreeList from '~/ide/components/ide_tree_list.vue';
import { createStore } from '~/ide/stores';
import FileTree from '~/vue_shared/components/file_tree.vue';
import { file } from '../helpers';
import { projectData } from '../mock_data';

describe('IdeTreeList component', () => {
  let wrapper;

  const mountComponent = ({ tree, loading = false } = {}) => {
    const store = createStore();
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'main';
    store.state.projects.abcproject = { ...projectData };
    store.state.trees = {
      ...store.state.trees,
      'abcproject/main': { tree, loading },
    };

    wrapper = shallowMount(IdeTreeList, {
      propsData: {
        viewerType: 'edit',
      },
      store,
    });
  };

  describe('normal branch', () => {
    const tree = [file('fileName')];

    it('emits tree-ready event', () => {
      mountComponent({ tree });

      expect(wrapper.emitted('tree-ready')).toEqual([[]]);
    });

    it('renders loading indicator', () => {
      mountComponent({ tree, loading: true });

      expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(3);
    });

    it('renders list of files', () => {
      mountComponent({ tree });

      expect(wrapper.findAllComponents(FileTree)).toHaveLength(1);
      expect(wrapper.findComponent(FileTree).props('file')).toEqual(tree[0]);
    });
  });

  describe('empty-branch state', () => {
    beforeEach(() => {
      mountComponent({ tree: [] });
    });

    it('emits tree-ready event', () => {
      expect(wrapper.emitted('tree-ready')).toEqual([[]]);
    });

    it('does not render files', () => {
      expect(wrapper.findAllComponents(FileTree)).toHaveLength(0);
    });

    it('renders empty state text', () => {
      expect(wrapper.text()).toBe('No files');
    });
  });
});
