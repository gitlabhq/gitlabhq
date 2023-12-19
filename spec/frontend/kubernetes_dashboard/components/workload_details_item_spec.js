import { shallowMount } from '@vue/test-utils';
import WorkloadDetailsItem from '~/kubernetes_dashboard/components/workload_details_item.vue';

let wrapper;

const propsData = {
  label: 'name',
};
const slots = {
  default: '<b>slot value</b>',
};

const createWrapper = () => {
  wrapper = shallowMount(WorkloadDetailsItem, {
    propsData,
    slots,
  });
};

const findLabel = () => wrapper.findComponent('label');

describe('Workload details item component', () => {
  beforeEach(() => {
    createWrapper();
  });

  it('renders the correct label', () => {
    expect(findLabel().text()).toBe(propsData.label);
  });

  it('renders slot content', () => {
    expect(wrapper.html()).toContain(slots.default);
  });
});
