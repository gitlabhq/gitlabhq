import { shallowMount } from '@vue/test-utils';
import FileTreeBrowser, { TREE_WIDTH } from '~/repository/file_tree_browser/file_tree_browser.vue';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import TreeList from '~/repository/file_tree_browser/components/tree_list.vue';

describe('FileTreeBrowser', () => {
  let wrapper;

  const findFileBrowserHeight = () => wrapper.findComponent(FileBrowserHeight);
  const findTreeList = () => wrapper.findComponent(TreeList);

  const createComponent = () => {
    wrapper = shallowMount(FileTreeBrowser, {
      propsData: {
        projectPath: 'group/project',
        currentRef: 'main',
        refType: 'branch',
      },
    });
  };

  beforeEach(() => createComponent());

  it('renders the file browser height component', () => {
    expect(findFileBrowserHeight().attributes('style')).toBe(`width: ${TREE_WIDTH}px;`);
  });

  it('renders the tree list component when not loading', () => {
    expect(findTreeList().exists()).toBe(true);
  });
});
