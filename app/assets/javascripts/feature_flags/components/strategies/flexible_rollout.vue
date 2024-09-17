<script>
import { GlFormInput, GlFormSelect } from '@gitlab/ui';
import { __ } from '~/locale';
import { PERCENT_ROLLOUT_GROUP_ID } from '../../constants';
import ParameterFormGroup from './parameter_form_group.vue';

export default {
  components: {
    GlFormInput,
    GlFormSelect,
    ParameterFormGroup,
  },
  props: {
    strategy: {
      required: true,
      type: Object,
    },
  },
  i18n: {
    percentageDescription: __('Enter an integer number between 0 and 100'),
    percentageInvalid: __('Percent rollout must be an integer number between 0 and 100'),
    percentageLabel: __('Percentage'),
    stickinessDescription: __('Consistency guarantee method'),
    stickinessLabel: __('Based on'),
  },
  stickinessOptions: [
    {
      value: 'default',
      text: __('Available ID'),
    },
    {
      value: 'userId',
      text: __('User ID'),
    },
    {
      value: 'sessionId',
      text: __('Session ID'),
    },
    {
      value: 'random',
      text: __('Random'),
    },
  ],
  computed: {
    isValid() {
      const percentageNum = Number(this.percentage);
      return Number.isInteger(percentageNum) && percentageNum >= 0 && percentageNum <= 100;
    },
    percentage() {
      return this.strategy?.parameters?.rollout ?? '100';
    },
    stickiness() {
      return this.strategy?.parameters?.stickiness ?? this.$options.stickinessOptions[0].value;
    },
  },
  methods: {
    onPercentageChange(value) {
      this.$emit('change', {
        parameters: {
          groupId: PERCENT_ROLLOUT_GROUP_ID,
          rollout: value,
          stickiness: this.stickiness,
        },
      });
    },
    onStickinessChange(value) {
      this.$emit('change', {
        parameters: {
          groupId: PERCENT_ROLLOUT_GROUP_ID,
          rollout: this.percentage,
          stickiness: value,
        },
      });
    },
  },
};
</script>
<template>
  <div class="gl-flex">
    <div class="gl-mr-7" data-testid="strategy-flexible-rollout-percentage">
      <parameter-form-group
        :label="$options.i18n.percentageLabel"
        :description="isValid ? $options.i18n.percentageDescription : ''"
        :invalid-feedback="$options.i18n.percentageInvalid"
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
            <span class="ml-1">%</span>
          </div>
        </template>
      </parameter-form-group>
    </div>

    <div class="gl-mr-7" data-testid="strategy-flexible-rollout-stickiness">
      <parameter-form-group
        :label="$options.i18n.stickinessLabel"
        :description="$options.i18n.stickinessDescription"
      >
        <template #default="{ inputId }">
          <gl-form-select
            :id="inputId"
            :value="stickiness"
            :options="$options.stickinessOptions"
            @change="onStickinessChange"
          />
        </template>
      </parameter-form-group>
    </div>
  </div>
</template>
