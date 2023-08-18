import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import OkrActionsSplitButton from '~/work_items/components/work_item_links/okr_actions_split_button.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const createComponent = () => {
  return extendedWrapper(
    shallowMount(OkrActionsSplitButton, {
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

  describe('OkrActionsSplitButton', () => {
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
