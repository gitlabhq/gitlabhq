import { shallowMount } from '@vue/test-utils';
import ReadyToMerge from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';

let wrapper;

function factory({ canMerge }) {
  wrapper = shallowMount(ReadyToMerge, {
    propsData: {
      mr: {},
    },
    data() {
      return { canMerge };
    },
  });
}

describe('Ready to merge state component', () => {
  it.each`
    canMerge
    ${true}
    ${false}
  `('renders permission text if canMerge ($canMerge) is false', ({ canMerge }) => {
    factory({ canMerge });

    expect(wrapper.element).toMatchSnapshot();
  });
});
