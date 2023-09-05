import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemRelationships from '~/work_items/components/work_item_relationships/work_item_relationships.vue';

describe('WorkItemRelationships', () => {
  let wrapper;

  const createComponent = async () => {
    wrapper = shallowMountExtended(WorkItemRelationships, {
      propsData: {
        workItem: {},
        workItemIid: '1',
        workItemFullpath: 'gitlab/path',
      },
    });

    await waitForPromises();
  };

  it('renders the component', () => {
    createComponent();

    expect(wrapper.find('.work-item-relationships').exists()).toBe(true);
  });
});
