import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTree from '~/work_items/components/work_item_links/work_item_tree.vue';
import OkrActionsSplitButton from '~/work_items/components/work_item_links/okr_actions_split_button.vue';

describe('WorkItemTree', () => {
  let wrapper;

  const findToggleButton = () => wrapper.findByTestId('toggle-tree');
  const findTreeBody = () => wrapper.findByTestId('tree-body');
  const findEmptyState = () => wrapper.findByTestId('tree-empty');
  const findToggleFormSplitButton = () => wrapper.findComponent(OkrActionsSplitButton);

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemTree, {
      propsData: { workItemType: 'Objective' },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('is expanded by default and displays Add button', () => {
    expect(findToggleButton().props('icon')).toBe('chevron-lg-up');
    expect(findTreeBody().exists()).toBe(true);
    expect(findToggleFormSplitButton().exists()).toBe(true);
  });

  it('collapses on click toggle button', async () => {
    findToggleButton().vm.$emit('click');
    await nextTick();

    expect(findToggleButton().props('icon')).toBe('chevron-lg-down');
    expect(findTreeBody().exists()).toBe(false);
  });

  it('displays empty state if there are no children', () => {
    expect(findEmptyState().exists()).toBe(true);
  });
});
