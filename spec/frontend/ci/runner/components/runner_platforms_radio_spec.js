import { GlFormRadio } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerPlatformsRadio from '~/ci/runner/components/runner_platforms_radio.vue';

const mockImg = 'mock.svg';
const mockValue = 'value';
const mockValue2 = 'value2';
const mockSlot = '<div>a</div>';

describe('RunnerPlatformsRadio', () => {
  let wrapper;

  const findDiv = () => wrapper.find('div');
  const findImg = () => wrapper.find('img');
  const findFormRadio = () => wrapper.findComponent(GlFormRadio);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RunnerPlatformsRadio, {
      propsData: {
        image: mockImg,
        value: mockValue,
        ...props,
      },
      ...options,
    });
  };

  describe('when its selectable', () => {
    beforeEach(() => {
      createComponent({
        props: { value: mockValue },
      });
    });

    it('shows the item is clickable', () => {
      expect(wrapper.classes('gl-cursor-pointer')).toBe(true);
    });

    it('shows radio option', () => {
      expect(findFormRadio().attributes('value')).toBe(mockValue);
    });

    it('emits when item is clicked', () => {
      findDiv().trigger('click');

      expect(wrapper.emitted('input')).toEqual([[mockValue]]);
    });

    it.each(['input', 'change'])('emits radio "%s" event', (event) => {
      findFormRadio().vm.$emit(event, mockValue2);

      expect(wrapper.emitted(event)).toEqual([[mockValue2]]);
    });

    it('shows image', () => {
      expect(findImg().element.src).toBe(mockImg);
      expect(findImg().attributes('aria-hidden')).toBe('true');
    });

    it('shows slot', () => {
      createComponent({
        slots: {
          default: mockSlot,
        },
      });

      expect(wrapper.html()).toContain(mockSlot);
    });

    describe('with no image', () => {
      beforeEach(() => {
        createComponent({
          props: { value: mockValue, image: null },
        });
      });

      it('shows no image', () => {
        expect(findImg().exists()).toBe(false);
      });
    });
  });

  describe('when its not selectable', () => {
    beforeEach(() => {
      createComponent({
        props: { value: null },
      });
    });

    it('shows the item is clickable', () => {
      expect(wrapper.classes('gl-cursor-pointer')).toBe(false);
    });

    it('does not emit when item is clicked', () => {
      findDiv().trigger('click');

      expect(wrapper.emitted('input')).toBe(undefined);
    });

    it('does not show a radio option', () => {
      expect(findFormRadio().exists()).toBe(false);
    });

    it('shows image', () => {
      expect(findImg().element.src).toBe(mockImg);
      expect(findImg().attributes('aria-hidden')).toBe('true');
    });

    it('shows slot', () => {
      createComponent({
        slots: {
          default: mockSlot,
        },
      });

      expect(wrapper.html()).toContain(mockSlot);
    });

    describe('with no image', () => {
      beforeEach(() => {
        createComponent({
          props: { value: null, image: null },
        });
      });

      it('shows no image', () => {
        expect(findImg().exists()).toBe(false);
      });
    });
  });

  describe('when selected', () => {
    beforeEach(() => {
      createComponent({
        props: { checked: mockValue },
      });
    });

    it('highlights the item', () => {
      expect(wrapper.classes('gl-bg-blue-50')).toBe(true);
      expect(wrapper.classes('gl-border-blue-500')).toBe(true);
    });

    it('shows radio option as selected', () => {
      expect(findFormRadio().attributes('value')).toBe(mockValue);
      expect(findFormRadio().props('checked')).toBe(mockValue);
    });
  });
});
