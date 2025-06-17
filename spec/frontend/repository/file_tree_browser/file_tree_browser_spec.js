import { shallowMount } from '@vue/test-utils';
import FileTreeBrowser, { TREE_WIDTH } from '~/repository/file_tree_browser/file_tree_browser.vue';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import TreeList from '~/repository/file_tree_browser/components/tree_list.vue';

describe('FileTreeBrowser', () => {
  let wrapper;

  const findFileBrowserHeight = () => wrapper.findComponent(FileBrowserHeight);
  const findTreeList = () => wrapper.findComponent(TreeList);

  const createComponent = (routeName = 'blobPathDecoded') => {
    wrapper = shallowMount(FileTreeBrowser, {
      propsData: {
        projectPath: 'group/project',
        currentRef: 'main',
        refType: 'branch',
      },
      mocks: {
        $route: {
          name: routeName,
        },
      },
    });
  };

  describe('when not on project overview page', () => {
    beforeEach(() => createComponent());

    it('renders the file browser height component', () => {
      expect(findFileBrowserHeight().exists()).toBe(true);
      expect(findFileBrowserHeight().attributes('style')).toBe(`width: ${TREE_WIDTH}px;`);
    });

    it('renders the tree list component', () => {
      expect(findTreeList().exists()).toBe(true);
    });
  });

  describe('when on project overview page', () => {
    beforeEach(() => createComponent('projectRoot'));

    it('does not render the file browser height component', () => {
      expect(findFileBrowserHeight().exists()).toBe(false);
    });

    it('does not render the tree list component', () => {
      expect(findTreeList().exists()).toBe(false);
    });
  });
});
