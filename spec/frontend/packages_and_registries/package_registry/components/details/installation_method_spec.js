import { shallowMount } from '@vue/test-utils';

import InstallationMethod from '~/packages_and_registries/package_registry/components/details/installation_method.vue';
import PersistedRadiogroup from '~/vue_shared/components/registry/persisted_radio_group.vue';

describe('InstallationMethod', () => {
  let wrapper;

  const defaultProps = { packageType: 'foo', options: [{ value: 'foo', label: 'bar' }] };

  const findPersistedRadiogroup = () => wrapper.findComponent(PersistedRadiogroup);

  function createComponent({ props = {} } = {}) {
    wrapper = shallowMount(InstallationMethod, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  describe('persisted radio selection', () => {
    it('exists', () => {
      createComponent();

      expect(findPersistedRadiogroup().exists()).toBe(true);
    });

    it('has the correct props', () => {
      createComponent();

      expect(findPersistedRadiogroup().props()).toMatchObject({
        storageKey: 'package_foo_installation_instructions',
        options: defaultProps.options,
      });
    });

    it('on change event emits a change event', () => {
      createComponent();

      findPersistedRadiogroup().vm.$emit('change', 'baz');

      expect(wrapper.emitted('change')).toEqual([['baz']]);
    });
  });
});
