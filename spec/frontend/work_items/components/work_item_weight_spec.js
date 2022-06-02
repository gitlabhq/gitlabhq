import { shallowMount } from '@vue/test-utils';
import WorkItemWeight from '~/work_items/components/work_item_weight.vue';

describe('WorkItemAssignees component', () => {
  let wrapper;

  const createComponent = ({ weight, hasIssueWeightsFeature = true } = {}) => {
    wrapper = shallowMount(WorkItemWeight, {
      propsData: {
        weight,
      },
      provide: {
        hasIssueWeightsFeature,
      },
    });
  };

  describe('weight licensed feature', () => {
    describe.each`
      description             | hasIssueWeightsFeature | exists
      ${'when available'}     | ${true}                | ${true}
      ${'when not available'} | ${false}               | ${false}
    `('$description', ({ hasIssueWeightsFeature, exists }) => {
      it(hasIssueWeightsFeature ? 'renders component' : 'does not render component', () => {
        createComponent({ hasIssueWeightsFeature });

        expect(wrapper.find('div').exists()).toBe(exists);
      });
    });
  });

  describe('weight text', () => {
    describe.each`
      description       | weight       | text
      ${'renders 1'}    | ${1}         | ${'1'}
      ${'renders 0'}    | ${0}         | ${'0'}
      ${'renders None'} | ${null}      | ${'None'}
      ${'renders None'} | ${undefined} | ${'None'}
    `('when weight is $weight', ({ description, weight, text }) => {
      it(description, () => {
        createComponent({ weight });

        expect(wrapper.text()).toContain(text);
      });
    });
  });
});
