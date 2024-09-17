<script>
import { GlFormInput } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { PERCENT_ROLLOUT_GROUP_ID } from '../../constants';
import ParameterFormGroup from './parameter_form_group.vue';

export default {
  components: {
    GlFormInput,
    ParameterFormGroup,
  },
  props: {
    strategy: {
      required: true,
      type: Object,
    },
  },
  i18n: {
    rolloutPercentageDescription: __('Enter an integer number between 0 and 100'),
    rolloutPercentageInvalid: s__(
      'FeatureFlags|Percent rollout must be an integer number between 0 and 100',
    ),
    rolloutPercentageLabel: s__('FeatureFlag|Percentage'),
  },
  computed: {
    isValid() {
      const percentageNum = Number(this.percentage);
      return Number.isInteger(percentageNum) && percentageNum >= 0 && percentageNum <= 100;
    },
    percentage() {
      return this.strategy?.parameters?.percentage ?? '100';
    },
  },
  methods: {
    onPercentageChange(value) {
      this.$emit('change', {
        parameters: {
          percentage: value,
          groupId: PERCENT_ROLLOUT_GROUP_ID,
        },
      });
    },
  },
};
</script>
<template>
  <parameter-form-group
    :label="$options.i18n.rolloutPercentageLabel"
    :description="isValid ? $options.i18n.rolloutPercentageDescription : ''"
    :invalid-feedback="$options.i18n.rolloutPercentageInvalid"
    :state="isValid"
  >
    <template #default="{ inputId }">
      <div class="gl-flex gl-items-center">
        <gl-form-input
          :id="inputId"
          :value="percentage"
          :state="isValid"
          type="number"
          min="0"
          max="100"
          width="xs"
          @input="onPercentageChange"
        />
        <span class="gl-ml-2">%</span>
      </div>
    </template>
  </parameter-form-group>
</template>
