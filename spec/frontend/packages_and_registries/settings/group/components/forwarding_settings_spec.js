import { GlFormGroup, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import component from '~/packages_and_registries/settings/group/components/forwarding_settings.vue';

describe('Forwarding Settings', () => {
  let wrapper;

  const defaultProps = {
    disabled: false,
    forwarding: false,
    label: 'label',
    lockForwarding: false,
    modelNames: {
      forwarding: 'forwardField',
      lockForwarding: 'lockForwardingField',
      isLocked: 'lockedField',
    },
  };

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMountExtended(component, {
      propsData,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findForwardingCheckbox = () => wrapper.findByTestId('forwarding-checkbox');
  const findLockForwardingCheckbox = () => wrapper.findByTestId('lock-forwarding-checkbox');

  it('has a form group', () => {
    mountComponent();

    expect(findFormGroup().exists()).toBe(true);
    expect(findFormGroup().attributes()).toMatchObject({
      label: defaultProps.label,
    });
  });

  describe.each`
    name                 | finder                        | label                                        | extraProps                  | field
    ${'forwarding'}      | ${findForwardingCheckbox}     | ${'Forward label package requests'}          | ${{ forwarding: true }}     | ${defaultProps.modelNames.forwarding}
    ${'lock forwarding'} | ${findLockForwardingCheckbox} | ${'Enforce label setting for all subgroups'} | ${{ lockForwarding: true }} | ${defaultProps.modelNames.lockForwarding}
  `('$name checkbox', ({ name, finder, label, extraProps, field }) => {
    it('is rendered', () => {
      mountComponent();
      expect(finder().exists()).toBe(true);
      expect(finder().text()).toMatchInterpolatedText(label);
      expect(finder().attributes('disabled')).toBeUndefined();
      expect(finder().attributes('checked')).toBeUndefined();
    });

    it(`is checked when ${name} set`, () => {
      mountComponent({ ...defaultProps, ...extraProps });

      expect(finder().attributes('checked')).toBe('true');
    });

    it(`emits an update event with field ${field} set`, () => {
      mountComponent();

      finder().vm.$emit('change', true);

      expect(wrapper.emitted('update')).toStrictEqual([[field, true]]);
    });
  });

  describe('disabled', () => {
    it('disables both checkboxes', () => {
      mountComponent({ ...defaultProps, disabled: true });

      expect(findForwardingCheckbox().attributes('disabled')).toEqual('true');
      expect(findLockForwardingCheckbox().attributes('disabled')).toEqual('true');
    });
  });
});
