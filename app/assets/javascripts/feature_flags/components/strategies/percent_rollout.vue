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
  translations: {
    rolloutPercentageDescription: __('Enter a whole number between 0 and 100'),
    rolloutPercentageInvalid: s__(
      'FeatureFlags|Percent rollout must be a whole number between 0 and 100',
    ),
    rolloutPercentageLabel: s__('FeatureFlag|Percentage'),
  },
  computed: {
    isValid() {
      return Number(this.percentage) >= 0 && Number(this.percentage) <= 100;
    },
    percentage() {
      return this.strategy?.parameters?.percentage ?? '';
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
    :label="$options.translations.rolloutPercentageLabel"
    :description="$options.translations.rolloutPercentageDescription"
    :invalid-feedback="$options.translations.rolloutPercentageInvalid"
    :state="isValid"
  >
    <template #default="{ inputId }">
      <div class="gl-display-flex gl-align-items-center">
        <gl-form-input
          :id="inputId"
          :value="percentage"
          :state="isValid"
          class="rollout-percentage gl-text-right gl-w-9"
          type="number"
          min="0"
          max="100"
          @input="onPercentageChange"
        />
        <span class="gl-ml-2">%</span>
      </div>
    </template>
  </parameter-form-group>
</template>
