import { GlFormInput } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import ParameterFormGroup from '~/feature_flags/components/strategies/parameter_form_group.vue';
import PercentRollout from '~/feature_flags/components/strategies/percent_rollout.vue';
import { PERCENT_ROLLOUT_GROUP_ID } from '~/feature_flags/constants';
import { percentRolloutStrategy } from '../../mock_data';

const DEFAULT_PROPS = {
  strategy: percentRolloutStrategy,
};

describe('~/feature_flags/components/strategies/percent_rollout.vue', () => {
  let wrapper;
  let input;
  let formGroup;

  const factory = (props = {}) =>
    mount(PercentRollout, { propsData: { ...DEFAULT_PROPS, ...props } });

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }

    wrapper = null;
  });

  describe('with valid percentage', () => {
    beforeEach(() => {
      wrapper = factory();

      input = wrapper.find(GlFormInput);
      formGroup = wrapper.find(ParameterFormGroup);
    });

    it('displays the current value', () => {
      expect(input.element.value).toBe(percentRolloutStrategy.parameters.percentage);
    });

    it('emits a change when the value changes', async () => {
      input.setValue('75');
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('change')).toEqual([
        [{ parameters: { percentage: '75', groupId: PERCENT_ROLLOUT_GROUP_ID } }],
      ]);
    });

    it('does not show errors', () => {
      expect(formGroup.attributes('state')).toBe('true');
    });
  });

  describe('with percentage that is out of range', () => {
    beforeEach(() => {
      wrapper = factory({ strategy: { parameters: { percentage: '101' } } });

      input = wrapper.find(GlFormInput);
      formGroup = wrapper.find(ParameterFormGroup);
    });

    it('shows errors', () => {
      expect(formGroup.attributes('state')).toBeUndefined();
    });
  });

  describe('with percentage that is not an integer number', () => {
    beforeEach(() => {
      wrapper = factory({ strategy: { parameters: { percentage: '3.14' } } });

      input = wrapper.find(GlFormInput);
      formGroup = wrapper.find(ParameterFormGroup);
    });

    it('shows errors', () => {
      expect(formGroup.attributes('state')).toBeUndefined();
    });
  });
});
