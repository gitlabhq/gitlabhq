import { shallowMount } from '@vue/test-utils';
import { assertProps } from 'helpers/assert_props';

import SlotSwitch from '~/vue_shared/components/slot_switch.vue';

describe('SlotSwitch', () => {
  const slots = {
    first: '<a>AGP</a>',
    second: '<p>PCI</p>',
  };

  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(SlotSwitch, {
      propsData,
      slots,
    });
  };

  const getChildrenHtml = () => wrapper.findAll('* *').wrappers.map((c) => c.html());

  it('throws an error if activeSlotNames is missing', () => {
    expect(() => assertProps(SlotSwitch, {})).toThrow(
      '[Vue warn]: Missing required prop: "activeSlotNames"',
    );
  });

  it('renders no slots if activeSlotNames is empty', () => {
    createComponent({
      activeSlotNames: [],
    });

    expect(getChildrenHtml().length).toBe(0);
  });

  it('renders one slot if activeSlotNames contains single slot name', () => {
    createComponent({
      activeSlotNames: ['first'],
    });

    expect(getChildrenHtml()).toEqual([slots.first]);
  });

  it('renders multiple slots if activeSlotNames contains multiple slot names', () => {
    createComponent({
      activeSlotNames: Object.keys(slots),
    });

    expect(getChildrenHtml()).toEqual(Object.values(slots));
  });
});
