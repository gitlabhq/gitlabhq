import { GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import component from '~/vue_shared/components/registry/persisted_radio_group.vue';

describe('Persisted radio group', () => {
  let wrapper;

  const defaultProps = {
    storageKey: 'foo_bar',
    options: [
      { value: 'maven', label: 'Maven' },
      { value: 'gradle', label: 'Gradle' },
    ],
    label: 'Installation method',
  };

  function createComponent({ props = {}, data = {} } = {}) {
    wrapper = shallowMountExtended(component, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      data() {
        return data;
      },
      stubs: {
        GlFormRadioGroup,
      },
    });
  }

  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const findGlFormRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findGlFormRadios = () => wrapper.findAllComponents(GlFormRadio);

  describe('local storage sync', () => {
    it('uses the local storage sync component with the correct props', () => {
      createComponent();

      expect(findLocalStorageSync().props('asString')).toBe(true);
    });

    it('passes the right props', () => {
      createComponent({ data: { selected: 'foo' } });

      expect(findLocalStorageSync().props()).toMatchObject({
        storageKey: defaultProps.storageKey,
        value: 'foo',
      });
    });

    it('on input event updates the model and emits event', async () => {
      const inputPayload = 'bar';
      createComponent();
      findLocalStorageSync().vm.$emit('input', inputPayload);

      await nextTick();

      expect(wrapper.emitted('change')).toStrictEqual([[inputPayload]]);
      expect(findLocalStorageSync().props('value')).toBe(inputPayload);
    });
  });

  describe('radio group', () => {
    it('has a radio group component', () => {
      createComponent();

      expect(findGlFormRadioGroup().exists()).toBe(true);
    });

    describe('Options', () => {
      it('has one item for each option', () => {
        createComponent();

        expect(findGlFormRadios()).toHaveLength(defaultProps.options.length);
      });

      it('on click updates the data and emits event', async () => {
        createComponent();

        expect(findGlFormRadioGroup().attributes('checked')).toEqual('maven');

        const selectedItem = 'gradle';
        findGlFormRadioGroup().vm.$emit('change', selectedItem);
        await nextTick();

        expect(wrapper.emitted('change').at(-1)).toStrictEqual([selectedItem]);
        expect(findGlFormRadioGroup().attributes('checked')).toEqual(selectedItem);
      });
    });
  });
});
