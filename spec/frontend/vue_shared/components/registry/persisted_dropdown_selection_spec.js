import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
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
    wrapper = mount(component, {
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
  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findGlListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findGlListboxToggleText = () =>
    findGlCollapsibleListbox().find('.gl-new-dropdown-button-text');

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

  describe('dropdown', () => {
    it('has a dropdown component', () => {
      createComponent();

      expect(findGlCollapsibleListbox().exists()).toBe(true);
    });

    describe('dropdown text', () => {
      it('when no selection shows the first', () => {
        createComponent();

        expect(findGlListboxToggleText().text()).toBe('Maven');
      });

      it('when an option is selected, shows that option label', async () => {
        createComponent();
        findGlCollapsibleListbox().vm.$emit('select', defaultProps.options[1].value);
        await nextTick();

        expect(findGlListboxToggleText().text()).toBe('Gradle');
      });
    });

    describe('dropdown items', () => {
      it('has one item for each option', () => {
        createComponent();

        expect(findGlListboxItems()).toHaveLength(defaultProps.options.length);
      });

      it('on click updates the data and emits event', async () => {
        createComponent();
        const selectedItem = 'gradle';

        expect(findGlCollapsibleListbox().props('selected')).toBe('maven');

        findGlCollapsibleListbox().vm.$emit('select', selectedItem);
        await nextTick();

        expect(wrapper.emitted('change').at(-1)).toStrictEqual([selectedItem]);
        expect(findGlCollapsibleListbox().props('selected')).toBe(selectedItem);
      });
    });
  });
});
