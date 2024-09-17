import { GlFormInput, GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import FlexibleRollout from '~/feature_flags/components/strategies/flexible_rollout.vue';
import ParameterFormGroup from '~/feature_flags/components/strategies/parameter_form_group.vue';
import { PERCENT_ROLLOUT_GROUP_ID } from '~/feature_flags/constants';
import { flexibleRolloutStrategy } from '../../mock_data';

const DEFAULT_PROPS = {
  strategy: flexibleRolloutStrategy,
};

describe('feature_flags/components/strategies/flexible_rollout.vue', () => {
  let wrapper;
  let percentageFormGroup;
  let percentageInput;
  let stickinessFormGroup;
  let stickinessSelect;

  const factory = (props = {}) =>
    shallowMount(FlexibleRollout, { propsData: { ...DEFAULT_PROPS, ...props } });

  describe('with valid percentage', () => {
    beforeEach(() => {
      wrapper = factory();

      percentageFormGroup = wrapper
        .find('[data-testid="strategy-flexible-rollout-percentage"]')
        .findComponent(ParameterFormGroup);
      percentageInput = percentageFormGroup.findComponent(GlFormInput);
      stickinessFormGroup = wrapper
        .find('[data-testid="strategy-flexible-rollout-stickiness"]')
        .findComponent(ParameterFormGroup);
      stickinessSelect = stickinessFormGroup.findComponent(GlFormSelect);
    });

    it('displays the current percentage value', () => {
      expect(percentageInput.attributes('value')).toBe(flexibleRolloutStrategy.parameters.rollout);
    });

    it('displays the current stickiness value', () => {
      expect(stickinessSelect.attributes('value')).toBe(
        flexibleRolloutStrategy.parameters.stickiness,
      );
    });

    it('emits a change when the percentage value changes', async () => {
      percentageInput.vm.$emit('input', '75');

      await nextTick();
      expect(wrapper.emitted('change')).toEqual([
        [
          {
            parameters: {
              rollout: '75',
              groupId: PERCENT_ROLLOUT_GROUP_ID,
              stickiness: flexibleRolloutStrategy.parameters.stickiness,
            },
          },
        ],
      ]);
    });

    it('emits a change when the stickiness value changes', async () => {
      stickinessSelect.vm.$emit('change', 'userId');
      await nextTick();
      expect(wrapper.emitted('change')).toEqual([
        [
          {
            parameters: {
              rollout: flexibleRolloutStrategy.parameters.rollout,
              groupId: PERCENT_ROLLOUT_GROUP_ID,
              stickiness: 'userId',
            },
          },
        ],
      ]);
    });

    it('does not show errors', () => {
      expect(percentageFormGroup.attributes('state')).toBe('true');
    });
  });

  describe('with percentage that is out of range', () => {
    beforeEach(() => {
      wrapper = factory({ strategy: { parameters: { rollout: '101' } } });
    });

    it('shows errors', () => {
      const formGroup = wrapper
        .find('[data-testid="strategy-flexible-rollout-percentage"]')
        .findComponent(ParameterFormGroup);

      expect(formGroup.attributes('state')).toBeUndefined();
    });
  });

  describe('with percentage that is not an integer number', () => {
    beforeEach(() => {
      wrapper = factory({ strategy: { parameters: { rollout: '3.14' } } });
    });

    it('shows errors', () => {
      const formGroup = wrapper
        .find('[data-testid="strategy-flexible-rollout-percentage"]')
        .findComponent(ParameterFormGroup);

      expect(formGroup.attributes('state')).toBeUndefined();
    });
  });
});
