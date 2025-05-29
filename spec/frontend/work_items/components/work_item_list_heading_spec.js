import { shallowMount } from '@vue/test-utils';
import WorkItemListHeading from '~/work_items/components/work_item_list_heading.vue';

describe('WorkItemListHeading', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(WorkItemListHeading, {
      slots: {
        default: '<div id="slot-content">Hello</div>',
      },
    });
  };
  it('displays the "Work items" title', () => {
    createComponent();
    const h1 = wrapper.find('h1');
    expect(h1.exists()).toBe(true);
    expect(h1.text()).toBe('Work items');
  });

  it('displays slot content', () => {
    createComponent();

    expect(wrapper.find('#slot-content').exists()).toBe(true);
  });
});
