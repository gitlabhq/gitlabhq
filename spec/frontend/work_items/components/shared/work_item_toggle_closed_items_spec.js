import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import WorkItemToggleClosedItems from '~/work_items/components/shared/work_item_toggle_closed_items.vue';

describe('WorkItemToggleClosedItems', () => {
  let wrapper;
  const findShowClosedButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ numberOfClosedItems = 0 }) => {
    wrapper = shallowMountExtended(WorkItemToggleClosedItems, {
      propsData: {
        numberOfClosedItems,
      },
    });
  };

  it('renders "Show Closed" button with plural text when number of closedItems are greater than 1', () => {
    createComponent({ numberOfClosedItems: 1 });

    const button = findShowClosedButton();
    expect(button.exists()).toBe(true);
    expect(button.text()).toBe('Show 1 closed item');
  });

  it('renders "Show Closed" button with plural textwhen closedItems is greater than 1', () => {
    createComponent({ numberOfClosedItems: 2 });

    const button = findShowClosedButton();
    expect(button.exists()).toBe(true);
    expect(button.text()).toBe('Show 2 closed items');
  });
});
