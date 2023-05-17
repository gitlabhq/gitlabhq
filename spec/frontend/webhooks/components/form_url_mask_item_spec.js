import { nextTick } from 'vue';
import { GlButton, GlFormInput } from '@gitlab/ui';

import FormUrlMaskItem from '~/webhooks/components/form_url_mask_item.vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('FormUrlMaskItem', () => {
  let wrapper;

  const defaultProps = {
    index: 0,
  };
  const mockKey = 'key';
  const mockValue = 'value';
  const mockInput = 'input';
  const mockFeedback = 'feedback';

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(FormUrlMaskItem, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findMaskItemKey = () => wrapper.findByTestId('mask-item-key');
  const findMaskItemValue = () => wrapper.findByTestId('mask-item-value');
  const findRemoveButton = () => wrapper.findComponent(GlButton);

  describe('template', () => {
    it('renders input for key and value', () => {
      createComponent({ props: { itemKey: mockKey, itemValue: mockValue } });

      const keyInput = findMaskItemKey();
      expect(keyInput.attributes()).toMatchObject({
        label: FormUrlMaskItem.i18n.keyLabel,
        state: 'true',
      });
      expect(keyInput.findComponent(GlFormInput).attributes()).toMatchObject({
        name: 'hook[url_variables][][key]',
        value: mockKey,
      });

      const valueInput = findMaskItemValue();
      expect(valueInput.attributes()).toMatchObject({
        label: FormUrlMaskItem.i18n.valueLabel,
        state: 'true',
      });
      expect(valueInput.findComponent(GlFormInput).attributes()).toMatchObject({
        name: 'hook[url_variables][][value]',
        value: mockValue,
      });
    });

    describe('when isEditing is true', () => {
      beforeEach(() => {
        createComponent({ props: { isEditing: true } });
      });

      it('renders disabled key and value', () => {
        expect(findMaskItemKey().findComponent(GlFormInput).attributes('disabled')).toBeDefined();
        expect(findMaskItemValue().findComponent(GlFormInput).attributes('disabled')).toBeDefined();
      });

      it('renders disabled remove button', () => {
        expect(findRemoveButton().attributes('disabled')).toBeDefined();
      });

      it('displays ************ as input value', () => {
        expect(findMaskItemValue().findComponent(GlFormInput).attributes('value')).toBe(
          '************',
        );
      });
    });

    describe('when keyInvalidFeedback is passed', () => {
      beforeEach(() => {
        createComponent({
          props: { keyInvalidFeedback: mockFeedback },
        });
      });

      it('sets validation message on key', () => {
        expect(findMaskItemKey().attributes('invalid-feedback')).toBe(mockFeedback);
        expect(findMaskItemKey().attributes('state')).toBeUndefined();
      });
    });

    describe('when valueInvalidFeedback is passed', () => {
      beforeEach(() => {
        createComponent({
          props: { valueInvalidFeedback: mockFeedback },
        });
      });

      it('sets validation message on value', () => {
        expect(findMaskItemValue().attributes('invalid-feedback')).toBe(mockFeedback);
        expect(findMaskItemValue().attributes('state')).toBeUndefined();
      });
    });

    describe('on key input', () => {
      beforeEach(async () => {
        createComponent({ props: { itemKey: mockKey, itemValue: mockValue } });

        findMaskItemKey().findComponent(GlFormInput).vm.$emit('input', mockInput);
        await nextTick();
      });

      it('emits input event', () => {
        expect(wrapper.emitted('input')).toEqual([
          [{ index: defaultProps.index, key: mockInput, value: mockValue }],
        ]);
      });
    });

    describe('on value input', () => {
      beforeEach(async () => {
        createComponent({ props: { itemKey: mockKey, itemValue: mockValue } });

        findMaskItemValue().findComponent(GlFormInput).vm.$emit('input', mockInput);
        await nextTick();
      });

      it('emits input event', () => {
        expect(wrapper.emitted('input')).toEqual([
          [{ index: defaultProps.index, key: mockKey, value: mockInput }],
        ]);
      });
    });

    it('renders remove button', () => {
      createComponent();

      expect(findRemoveButton().props('icon')).toBe('remove');
    });

    describe('when remove button is clicked', () => {
      const mockIndex = 5;

      beforeEach(async () => {
        createComponent({ props: { index: mockIndex } });

        findRemoveButton().vm.$emit('click');
        await nextTick();
      });

      it('emits remove event', () => {
        expect(wrapper.emitted('remove')).toEqual([[mockIndex]]);
      });
    });
  });
});
