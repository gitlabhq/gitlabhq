import { GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import CanaryIngress from '~/environments/components/canary_ingress.vue';
import { CANARY_UPDATE_MODAL } from '~/environments/constants';

describe('/environments/components/canary_ingress.vue', () => {
  let wrapper;

  const setWeightTo = (weightWrapper, x) =>
    weightWrapper
      .findAll(GlDropdownItem)
      .at(x / 5)
      .vm.$emit('click');

  const createComponent = () => {
    wrapper = mount(CanaryIngress, {
      propsData: {
        canaryIngress: {
          canary_weight: 60,
        },
      },
      directives: {
        GlModal: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }

    wrapper = null;
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
      const options = stableWeightDropdown.findAll(GlDropdownItem);
      expect(options).toHaveLength(21);
      options.wrappers.forEach((w, i) => expect(w.text()).toBe((i * 5).toString()));
    });

    it('is set to open the change modal', () => {
      stableWeightDropdown
        .findAll(GlDropdownItem)
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
        .findAll(GlDropdownItem)
        .wrappers.forEach((w, i) => expect(w.text()).toBe((i * 5).toString()));
    });

    it('is set to open the change modal', () => {
      const options = canaryWeightDropdown.findAll(GlDropdownItem);
      expect(options).toHaveLength(21);
      options.wrappers.forEach((w, i) => expect(w.text()).toBe((i * 5).toString()));
    });
  });
});
