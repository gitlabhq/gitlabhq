import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';

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

      expect(wrapper.find('*').exists()).toBe(false);
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

  describe('scrollOnError', () => {
    describe('when scrollOnError is true', () => {
      beforeEach(() => {
        createComponent({ propsData: { scrollOnError: true } });
      });

      it('scrolls to error when errors appear', async () => {
        // setProps is justified here because we are testing the component's
        // reactive behavior to when an alert appears.
        // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
        wrapper.setProps({ errors: ['foo'] });

        await nextTick();
        await nextTick(); // Wait two ticks to allow alert to render, followed by scrollIntoView to activate

        expect(wrapper.element.scrollIntoView).toHaveBeenCalledWith({
          behavior: 'smooth',
          block: 'center',
        });
      });
    });

    describe('when scrollOnError is false', () => {
      beforeEach(() => {
        createComponent({ propsData: { scrollOnError: false } });
      });

      it('does not scroll to error when errors appear', async () => {
        // setProps is justified here because we are testing the component's
        // reactive behavior to when an alert appears.
        // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
        wrapper.setProps({ errors: ['foo'] });

        await nextTick();
        await nextTick(); // Wait two ticks to allow alert to render, followed by scrollIntoView to activate

        expect(wrapper.element.scrollIntoView).not.toHaveBeenCalled();
      });
    });
  });
});
