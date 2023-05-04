import { GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import CanaryIngress from '~/environments/components/canary_ingress.vue';
import { CANARY_UPDATE_MODAL } from '~/environments/constants';
import { rolloutStatus } from './graphql/mock_data';

describe('/environments/components/canary_ingress.vue', () => {
  let wrapper;

  const setWeightTo = (weightWrapper, x) =>
    weightWrapper
      .findAllComponents(GlDropdownItem)
      .at(x / 5)
      .vm.$emit('click');

  const createComponent = (props = {}, options = {}) => {
    wrapper = mount(CanaryIngress, {
      propsData: {
        canaryIngress: {
          canary_weight: 60,
        },
        ...props,
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('stable weight', () => {
    let stableWeightDropdown;

    beforeEach(() => {
      stableWeightDropdown = wrapper.find('[data-testid="stable-weight"]');
    });

    it('displays the current stable weight', () => {
      expect(stableWeightDropdown.props('text')).toBe('40');
    });

    it('emits a change with the new canary weight', () => {
      setWeightTo(stableWeightDropdown, 15);

      expect(wrapper.emitted('change')).toContainEqual([85]);
    });

    it('lists options from 0 to 100 in increments of 5', () => {
      const options = stableWeightDropdown.findAllComponents(GlDropdownItem);
      expect(options).toHaveLength(21);
      options.wrappers.forEach((w, i) => expect(w.text()).toBe((i * 5).toString()));
    });

    it('is set to open the change modal', () => {
      stableWeightDropdown
        .findAllComponents(GlDropdownItem)
        .wrappers.forEach((w) =>
          expect(getBinding(w.element, 'gl-modal')).toMatchObject({ value: CANARY_UPDATE_MODAL }),
        );
    });
  });

  describe('canary weight', () => {
    let canaryWeightDropdown;

    beforeEach(() => {
      canaryWeightDropdown = wrapper.find('[data-testid="canary-weight"]');
    });

    it('displays the current canary weight', () => {
      expect(canaryWeightDropdown.props('text')).toBe('60');
    });

    it('emits a change with the new canary weight', () => {
      setWeightTo(canaryWeightDropdown, 15);

      expect(wrapper.emitted('change')).toContainEqual([15]);
    });

    it('lists options from 0 to 100 in increments of 5', () => {
      canaryWeightDropdown
        .findAllComponents(GlDropdownItem)
        .wrappers.forEach((w, i) => expect(w.text()).toBe((i * 5).toString()));
    });

    it('is set to open the change modal', () => {
      canaryWeightDropdown
        .findAllComponents(GlDropdownItem)
        .wrappers.forEach((w) =>
          expect(getBinding(w.element, 'gl-modal')).toMatchObject({ value: CANARY_UPDATE_MODAL }),
        );
    });
  });

  describe('graphql', () => {
    beforeEach(() => {
      createComponent({
        graphql: true,
        canaryIngress: rolloutStatus.canaryIngress,
      });
    });

    it('shows the correct weight', () => {
      const canaryWeightDropdown = wrapper.find('[data-testid="canary-weight"]');
      expect(canaryWeightDropdown.props('text')).toBe('50');
    });
  });
});
