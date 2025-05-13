import { nextTick } from 'vue';
import { GlBadge, GlButton, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TreeList from '~/repository/file_tree_browser/components/tree_list.vue';

describe('TreeList', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findListViewButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findTreeViewButton = () => wrapper.findAllComponents(GlButton).at(1);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findNoFilesMessage = () => wrapper.findByText('No files found');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(TreeList, {
      propsData: { totalFilesCount: 5, ...props },
    });
  };

  beforeEach(() => createComponent());

  it('renders the header and file count badge', () => {
    expect(wrapper.find('h5').text()).toBe('Files');
    expect(findBadge().text()).toBe('5');
  });

  it('renders list and tree view buttons', () => {
    expect(findListViewButton().props('selected')).toBe(true);
    expect(findTreeViewButton().props('selected')).toBe(false);
  });

  it('selects the tree view button when clicked', async () => {
    findTreeViewButton().vm.$emit('click');
    await nextTick();

    expect(findTreeViewButton().props('selected')).toBe(true);
    expect(findListViewButton().props('selected')).toBe(false);
  });

  it('selects the list view button when clicked', async () => {
    findListViewButton().vm.$emit('click');
    await nextTick();

    expect(findListViewButton().props('selected')).toBe(true);
    expect(findTreeViewButton().props('selected')).toBe(false);
  });

  it('renders search box', () => {
    expect(findSearchBox().exists()).toBe(true);
  });

  it('renders empty state message when no files are available', () => {
    expect(findNoFilesMessage().exists()).toBe(true);
  });
});
