import { GlFormCheckbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SignupCheckbox from '~/pages/admin/application_settings/general/components/signup_checkbox.vue';

describe('Signup Form', () => {
  let wrapper;

  const props = {
    name: 'name',
    helpText: 'some help text',
    label: 'a label',
    value: true,
    dataTestId: 'test-id',
  };

  const mountComponent = (additionalProps = {}) => {
    wrapper = shallowMount(SignupCheckbox, {
      propsData: { ...props, ...additionalProps },
      stubs: {
        GlFormCheckbox,
      },
    });
  };

  const findByTestId = (id) => wrapper.find(`[data-testid="${id}"]`);
  const findHiddenInput = () => findByTestId('input');
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findCheckboxLabel = () => findByTestId('label');
  const findHelpText = () => findByTestId('helpText');

  describe('Signup Checkbox', () => {
    beforeEach(() => {
      mountComponent();
    });

    describe('hidden input element', () => {
      it('gets passed correct values from props', () => {
        expect(findHiddenInput().attributes('name')).toBe(props.name);

        expect(findHiddenInput().attributes('value')).toBe('1');
      });
    });

    describe('checkbox', () => {
      it('gets passed correct checked value', () => {
        expect(findCheckbox().attributes('checked')).toBe('true');
      });

      it('gets passed correct label', () => {
        expect(findCheckboxLabel().text()).toBe(props.label);
      });

      it('gets passed correct help text', () => {
        expect(findHelpText().text()).toBe(props.helpText);
      });

      it('gets passed data qa selector', () => {
        expect(findCheckbox().attributes('data-testid')).toBe(props.dataTestId);
      });

      it('gets passed `disabled` property', () => {
        mountComponent({ disabled: true });
        expect(findCheckbox().attributes('disabled')).toBe('true');
      });
    });
  });
});
