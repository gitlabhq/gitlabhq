import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import CanaryIngress from '~/environments/components/canary_ingress.vue';
import { rolloutStatus } from './graphql/mock_data';

jest.mock('lodash/uniqueId', () => {
  return jest.fn((input) => input);
});

describe('/environments/components/canary_ingress.vue', () => {
  let wrapper;

  const setWeightTo = (weightWrapper, x) => {
    weightWrapper.vm.$emit('select', x);
  };

  const createComponent = (props = {}, options = {}) => {
    wrapper = mountExtended(CanaryIngress, {
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
      stableWeightDropdown = extendedWrapper(wrapper.find('#stable-weight-'));
    });

    it('displays the current stable weight', () => {
      expect(stableWeightDropdown.props('selected')).toBe(40);
    });

    it('emits a change with the new canary weight', () => {
      setWeightTo(stableWeightDropdown, 15);

      expect(wrapper.emitted('change')).toContainEqual([85]);
    });

    it('lists options from 0 to 100 in increments of 5', () => {
      const options = stableWeightDropdown.props('items');
      expect(options).toHaveLength(21);
      options.forEach((option, i) => expect(option.text).toBe((i * 5).toString()));
    });
  });

  describe('canary weight', () => {
    let canaryWeightDropdown;

    beforeEach(() => {
      canaryWeightDropdown = wrapper.find('#canary-weight-');
    });

    it('displays the current canary weight', () => {
      expect(canaryWeightDropdown.props('selected')).toBe(60);
    });

    it('emits a change with the new canary weight', () => {
      setWeightTo(canaryWeightDropdown, 15);

      expect(wrapper.emitted('change')).toContainEqual([15]);
    });

    it('lists options from 0 to 100 in increments of 5', () => {
      const options = canaryWeightDropdown.props('items');
      expect(options).toHaveLength(21);
      options.forEach((option, i) => expect(option.text).toBe((i * 5).toString()));
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
      const canaryWeightDropdown = wrapper.find('#canary-weight-');
      expect(canaryWeightDropdown.props('selected')).toBe(50);
    });
  });
});
