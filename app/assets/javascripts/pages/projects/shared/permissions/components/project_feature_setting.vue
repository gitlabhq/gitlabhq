<script>
import { GlIcon, GlToggle } from '@gitlab/ui';
import { featureAccessLevelNone } from '../constants';

export default {
  components: {
    GlIcon,
    GlToggle,
  },
  model: {
    prop: 'value',
    event: 'change',
  },
  props: {
    label: {
      type: String,
      required: false,
      default: '',
    },
    name: {
      type: String,
      required: false,
      default: '',
    },
    options: {
      type: Array,
      required: false,
      default: () => [],
    },
    value: {
      type: Number,
      required: false,
      default: 0,
    },
    disabledInput: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabledSelectInput: {
      type: Boolean,
      required: false,
      default: false,
    },
    showToggle: {
      type: Boolean,
      required: false,
      default: true,
    },
    accessControlForced: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      valueWhenFeatureLastEnabled: this.isFeatureEnabled(this.value)
        ? this.value
        : this.lastOptionValue(),
    };
  },
  computed: {
    internalValue: {
      get() {
        if (this.accessControlForced && this.options.length > 0) {
          return this.options[0].value;
        }
        return this.value;
      },
      set(value) {
        this.$emit('change', value);
      },
    },
    featureEnabled() {
      return this.isFeatureEnabled(this.value);
    },
    displayOptions() {
      if (this.featureEnabled) {
        return this.options;
      }
      return [featureAccessLevelNone];
    },
    disableSelectInput() {
      return (
        this.disabledSelectInput ||
        this.disabledInput ||
        !this.featureEnabled ||
        this.displayOptions.length < 2 ||
        this.accessControlForced
      );
    },
    valueWhenFeatureEnabled() {
      return this.isValueInOptions(this.valueWhenFeatureLastEnabled)
        ? this.valueWhenFeatureLastEnabled
        : this.lastOptionValue();
    },
  },
  watch: {
    value(newValue) {
      if (this.isFeatureEnabled(newValue)) {
        this.valueWhenFeatureLastEnabled = newValue;
      }
    },
  },
  methods: {
    lastOptionValue() {
      return this.options[this.options.length - 1].value;
    },
    isFeatureEnabled(value) {
      return value !== 0;
    },
    isValueInOptions(value) {
      return this.options.some(({ value: optionValue }) => optionValue === value);
    },
    toggleFeature(featureEnabled) {
      this.$emit('change', featureEnabled ? this.valueWhenFeatureEnabled : 0);
    },
  },
};
</script>

<template>
  <div :data-for="name" class="project-feature-controls gl-mx-0 gl-mt-2 gl-flex gl-items-center">
    <input v-if="name" :name="name" :value="value" type="hidden" />
    <gl-toggle
      v-if="showToggle"
      class="gl-mr-3"
      :value="featureEnabled"
      :disabled="disabledInput"
      :label="label"
      label-position="hidden"
      @change="toggleFeature"
    />
    <div class="select-wrapper gl-grow">
      <select
        v-model="internalValue"
        :disabled="disableSelectInput"
        class="form-control project-repo-select select-control"
      >
        <option v-for="option in displayOptions" :key="option.label" :value="option.value">
          {{ option.label }}
        </option>
      </select>
      <gl-icon name="chevron-down" class="gl-absolute gl-right-3 gl-top-3" variant="default" />
    </div>
  </div>
</template>
