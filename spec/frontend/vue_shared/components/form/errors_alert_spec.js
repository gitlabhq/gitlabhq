import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FormErrorsAlert from '~/vue_shared/components/form/errors_alert.vue';

describe('FormErrorsAlert', () => {
  let wrapper;

  const defaultPropsData = {
    errors: ['Foo', 'Bar', 'Baz'],
  };

  function createComponent({ propsData = {} } = {}) {
    wrapper = shallowMount(FormErrorsAlert, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  }

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('when there are no errors', () => {
    it('renders nothing', () => {
      createComponent({ propsData: { errors: [] } });

      expect(wrapper.html()).toBe('');
    });
  });

  describe('when there is one error', () => {
    it('renders correct title and message', () => {
      createComponent({ propsData: { errors: ['Foo'] } });

      expect(findAlert().props('title')).toBe('The form contains the following error:');
      expect(findAlert().text()).toContain('Foo');
    });
  });

  describe('when there are multiple errors', () => {
    it('renders correct title and message', () => {
      createComponent();

      expect(findAlert().props('title')).toBe('The form contains the following errors:');
      expect(findAlert().text()).toContain('Foo');
      expect(findAlert().text()).toContain('Bar');
      expect(findAlert().text()).toContain('Baz');
    });
  });

  describe('when alert is dismissed', () => {
    it('emits input event with empty array as payload', () => {
      createComponent();

      findAlert().vm.$emit('dismiss');

      expect(wrapper.emitted('input')).toEqual([[[]]]);
    });
  });
});
