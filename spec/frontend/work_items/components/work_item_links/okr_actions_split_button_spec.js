import { GlDropdownSectionHeader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import OkrActionsSplitButton from '~/work_items/components/work_item_links/okr_actions_split_button.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const createComponent = () => {
  return extendedWrapper(shallowMount(OkrActionsSplitButton));
};

describe('RelatedItemsTree', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('OkrActionsSplitButton', () => {
    describe('template', () => {
      it('renders objective and key results sections', () => {
        expect(wrapper.findAllComponents(GlDropdownSectionHeader).at(0).text()).toContain(
          'Objective',
        );

        expect(wrapper.findAllComponents(GlDropdownSectionHeader).at(1).text()).toContain(
          'Key result',
        );
      });
    });
  });
});
