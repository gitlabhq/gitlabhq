import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import component from '~/vue_shared/components/registry/persisted_dropdown_selection.vue';

describe('Persisted dropdown selection', () => {
  let wrapper;

  const defaultProps = {
    storageKey: 'foo_bar',
    options: [
      { value: 'maven', label: 'Maven' },
      { value: 'gradle', label: 'Gradle' },
    ],
  };

  function createComponent({ props = {}, data = {} } = {}) {
    wrapper = shallowMount(component, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      data() {
        return data;
      },
    });
  }

  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('local storage sync', () => {
    it('uses the local storage sync component', () => {
      createComponent();

      expect(findLocalStorageSync().exists()).toBe(true);
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

  describe('dropdown', () => {
    it('has a dropdown component', () => {
      createComponent();

      expect(findDropdown().exists()).toBe(true);
    });

    describe('dropdown text', () => {
      it('when no selection shows the first', () => {
        createComponent();

        expect(findDropdown().props('text')).toBe('Maven');
      });

      it('when an option is selected, shows that option label', () => {
        createComponent({ data: { selected: defaultProps.options[1].value } });

        expect(findDropdown().props('text')).toBe('Gradle');
      });
    });

    describe('dropdown items', () => {
      it('has one item for each option', () => {
        createComponent();

        expect(findDropdownItems()).toHaveLength(defaultProps.options.length);
      });

      it('binds the correct props', () => {
        createComponent({ data: { selected: defaultProps.options[0].value } });

        expect(findDropdownItems().at(0).props()).toMatchObject({
          isChecked: true,
          isCheckItem: true,
        });

        expect(findDropdownItems().at(1).props()).toMatchObject({
          isChecked: false,
          isCheckItem: true,
        });
      });

      it('on click updates the data and emits event', async () => {
        createComponent({ data: { selected: defaultProps.options[0].value } });
        expect(findDropdownItems().at(0).props('isChecked')).toBe(true);

        findDropdownItems().at(1).vm.$emit('click');

        await nextTick();

        expect(wrapper.emitted('change')).toStrictEqual([['gradle']]);
        expect(findDropdownItems().at(0).props('isChecked')).toBe(false);
        expect(findDropdownItems().at(1).props('isChecked')).toBe(true);
      });
    });
  });
});
