import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SegmentedControlButtonGroup from '~/vue_shared/components/segmented_control_button_group.vue';

const DEFAULT_OPTIONS = [
  { text: 'Lorem', value: 'abc' },
  { text: 'Ipsum', value: 'def' },
  { text: 'Foo', value: 'x', disabled: true },
  { text: 'Dolar', value: 'ghi' },
];

describe('~/vue_shared/components/segmented_control_button_group.vue', () => {
  let wrapper;

  const createComponent = (props = {}, scopedSlots = {}) => {
    wrapper = shallowMount(SegmentedControlButtonGroup, {
      propsData: {
        value: DEFAULT_OPTIONS[0].value,
        options: DEFAULT_OPTIONS,
        ...props,
      },
      scopedSlots,
    });
  };

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const findButtons = () => findButtonGroup().findAllComponents(GlButton);
  const findButtonsData = () =>
    findButtons().wrappers.map((x) => ({
      selected: x.props('selected'),
      text: x.text(),
      disabled: x.props('disabled'),
    }));
  const findButtonWithText = (text) => findButtons().wrappers.find((x) => x.text() === text);

  const optionsAsButtonData = (options) =>
    options.map(({ text, disabled = false }) => ({
      selected: false,
      text,
      disabled,
    }));

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders button group', () => {
      expect(findButtonGroup().exists()).toBe(true);
    });

    it('renders buttons', () => {
      const expectation = optionsAsButtonData(DEFAULT_OPTIONS);
      expectation[0].selected = true;

      expect(findButtonsData()).toEqual(expectation);
    });

    describe.each(DEFAULT_OPTIONS.filter((x) => !x.disabled))(
      'when button clicked %p',
      ({ text, value }) => {
        it('emits input with value', () => {
          expect(wrapper.emitted('input')).toBeUndefined();

          findButtonWithText(text).vm.$emit('click');

          expect(wrapper.emitted('input')).toEqual([[value]]);
        });
      },
    );
  });

  const VALUE_TEST_CASES = [0, 1, 3].map((index) => [DEFAULT_OPTIONS[index].value, index]);

  describe.each(VALUE_TEST_CASES)('with value=%s', (value, index) => {
    it(`renders selected button at ${index}`, () => {
      createComponent({ value });

      const expectation = optionsAsButtonData(DEFAULT_OPTIONS);
      expectation[index].selected = true;

      expect(findButtonsData()).toEqual(expectation);
    });
  });

  describe('with button-content slot', () => {
    it('renders button content based on slot', () => {
      createComponent(
        {},
        {
          'button-content': `<template #button-content="{ text }">In a slot - {{ text }}</template>`,
        },
      );

      expect(findButtonsData().map((x) => x.text)).toEqual(
        DEFAULT_OPTIONS.map((x) => `In a slot - ${x.text}`),
      );
    });
  });
});
