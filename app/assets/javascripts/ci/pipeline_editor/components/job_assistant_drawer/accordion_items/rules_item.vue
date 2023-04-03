<script>
import {
  GlFormGroup,
  GlAccordionItem,
  GlFormInput,
  GlFormSelect,
  GlFormCheckbox,
} from '@gitlab/ui';
import { i18n, JOB_RULES_WHEN, JOB_RULES_START_IN } from '../constants';

export default {
  i18n,
  whenOptions: Object.values(JOB_RULES_WHEN),
  unitOptions: Object.values(JOB_RULES_START_IN),
  components: {
    GlAccordionItem,
    GlFormInput,
    GlFormSelect,
    GlFormCheckbox,
    GlFormGroup,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
    isStartValid: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      startInNumber: 1,
      startInUnit: JOB_RULES_START_IN.second.value,
    };
  },
  computed: {
    isDelayed() {
      return this.job.rules[0].when === JOB_RULES_WHEN.delayed.value;
    },
  },
  methods: {
    updateStartIn() {
      const plural = this.startInNumber > 1 ? 's' : '';
      this.$emit(
        'update-job',
        'rules[0].start_in',
        `${this.startInNumber} ${this.startInUnit}${plural}`,
      );
    },
  },
};
</script>
<template>
  <gl-accordion-item :title="$options.i18n.RULES">
    <div class="gl-display-flex">
      <gl-form-group class="gl-flex-grow-1 gl-flex-basis-half gl-mr-3" :label="$options.i18n.WHEN">
        <gl-form-select
          class="gl-flex-grow-1 gl-flex-basis-half gl-mr-3"
          :options="$options.whenOptions"
          data-testid="rules-when-select"
          :value="job.rules[0].when"
          @input="$emit('update-job', 'rules[0].when', $event)"
        />
      </gl-form-group>
      <gl-form-group
        class="gl-flex-grow-1 gl-flex-basis-half"
        :invalid-feedback="$options.i18n.INVALID_START_IN"
        :state="isStartValid"
      >
        <div class="gl-display-flex gl-mt-5">
          <gl-form-input
            v-model="startInNumber"
            class="gl-flex-grow-1 gl-flex-basis-half gl-mr-3"
            data-testid="rules-start-in-number-input"
            type="number"
            :state="isStartValid"
            :class="{ 'gl-visibility-hidden': !isDelayed }"
            number
            @input="updateStartIn"
          />
          <gl-form-select
            v-model="startInUnit"
            class="gl-flex-grow-1 gl-flex-basis-half"
            data-testid="rules-start-in-unit-select"
            :state="isStartValid"
            :class="{ 'gl-visibility-hidden': !isDelayed }"
            :options="$options.unitOptions"
            @input="updateStartIn"
          />
        </div>
      </gl-form-group>
    </div>
    <gl-form-group>
      <gl-form-checkbox
        :checked="job.rules[0].allow_failure"
        data-testid="rules-allow-failure-checkbox"
        @input="$emit('update-job', 'rules[0].allow_failure', $event)"
      >
        {{ $options.i18n.ALLOW_FAILURE }}
      </gl-form-checkbox>
    </gl-form-group>
  </gl-accordion-item>
</template>
