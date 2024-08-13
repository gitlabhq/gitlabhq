import { nextTick } from 'vue';
import { GlButton, GlFormInput } from '@gitlab/ui';

import FormCustomHeaderItem from '~/webhooks/components/form_custom_header_item.vue';
import { MASK_ITEM_VALUE_HIDDEN } from '~/webhooks/constants';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('FormCustomHeaderItem', () => {
  let wrapper;

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(FormCustomHeaderItem, {
      propsData: { index: 0, keyState: true, valueState: true, ...props },
    });
  };

  const findCustomHeaderItemKey = () => wrapper.findByTestId('custom-header-item-key');
  const findCustomHeaderItemValue = () => wrapper.findByTestId('custom-header-item-value');
  const findRemoveButton = () => wrapper.findComponent(GlButton);

  it('renders input for key and value', () => {
    const headerKey = 'key';
    const headerValue = 'value';

    createComponent({ props: { headerKey, headerValue } });

    const keyInput = findCustomHeaderItemKey();
    const valueInput = findCustomHeaderItemValue();

    expect(keyInput.attributes()).toMatchObject({
      label: 'Header name',
    });
    expect(keyInput.findComponent(GlFormInput).attributes()).toMatchObject({
      name: 'hook[custom_headers][][key]',
      value: headerKey,
      state: 'true',
    });

    expect(valueInput.attributes()).toMatchObject({
      label: 'Header value',
    });
    expect(valueInput.findComponent(GlFormInput).attributes()).toMatchObject({
      name: 'hook[custom_headers][][value]',
      value: headerValue,
      state: 'true',
    });
  });

  describe('when value is the secret mask', () => {
    it('renders readonly key and value', () => {
      createComponent({ props: { headerKey: 'key', headerValue: MASK_ITEM_VALUE_HIDDEN } });

      expect(
        findCustomHeaderItemKey().findComponent(GlFormInput).attributes('readonly'),
      ).toBeDefined();
      expect(
        findCustomHeaderItemValue().findComponent(GlFormInput).attributes('readonly'),
      ).toBeDefined();
    });
  });

  it('renders remove button', () => {
    createComponent({ props: { headerKey: 'key', headerValue: 'value' } });

    expect(findRemoveButton().props('icon')).toBe('remove');
  });

  describe('when remove button is clicked', () => {
    it('emits remove event', async () => {
      createComponent({ props: { headerKey: 'key', headerValue: 'value' } });

      findRemoveButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('remove')).toHaveLength(1);
    });
  });

  describe('events', () => {
    const headerKey = 'key';
    const headerValue = 'value';
    const mockInput = 'input';

    it('update:header-key on key input', async () => {
      createComponent({ props: { headerKey, headerValue } });

      findCustomHeaderItemKey().findComponent(GlFormInput).vm.$emit('input', mockInput);
      await nextTick();

      expect(wrapper.emitted('update:header-key')).toEqual([[mockInput]]);
    });

    it('update:header-value on value input', async () => {
      createComponent({ props: { headerKey, headerValue } });

      findCustomHeaderItemValue().findComponent(GlFormInput).vm.$emit('input', mockInput);
      await nextTick();

      expect(wrapper.emitted('update:header-value')).toEqual([[mockInput]]);
    });
  });
});
