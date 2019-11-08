import { shallowMount } from '@vue/test-utils';

import SlotSwitch from '~/vue_shared/components/slot_switch';

describe('SlotSwitch', () => {
  const slots = {
    first: '<a>AGP</a>',
    second: '<p>PCI</p>',
  };

  let wrapper;

  const createComponent = propsData => {
    wrapper = shallowMount(SlotSwitch, {
      propsData,
      slots,
      sync: false,
    });
  };

  const getChildrenHtml = () => wrapper.findAll('* *').wrappers.map(c => c.html());

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('throws an error if activeSlotNames is missing', () => {
    expect(createComponent).toThrow('[Vue warn]: Missing required prop: "activeSlotNames"');
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
