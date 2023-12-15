import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import WorkItemActionsSplitButton from '~/work_items/components/work_item_links/work_item_actions_split_button.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const okrActions = [
  {
    name: 'Objective',
    items: [
      {
        text: 'New objective',
      },
      {
        text: 'Existing objective',
      },
    ],
  },
  {
    name: 'Key result',
    items: [
      {
        text: 'New key result',
      },
      {
        text: 'Existing key result',
      },
    ],
  },
];

const createComponent = () => {
  return extendedWrapper(
    shallowMount(WorkItemActionsSplitButton, {
      propsData: {
        actions: okrActions,
      },
      stubs: {
        GlDisclosureDropdown,
      },
    }),
  );
};

describe('RelatedItemsTree', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('WorkItemActionsSplitButton', () => {
    describe('template', () => {
      it('renders objective and key results sections', () => {
        expect(wrapper.findAllComponents(GlDisclosureDropdownGroup).at(0).props('group').name).toBe(
          'Objective',
        );

        expect(wrapper.findAllComponents(GlDisclosureDropdownGroup).at(1).props('group').name).toBe(
          'Key result',
        );
      });
    });
  });
});
