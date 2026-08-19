<script>
import { GlIcon, GlToggle, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { featureAccessLevelNone } from '../constants';

export default {
  name: 'ProjectFeatureSetting',
  components: {
    GlIcon,
    GlToggle,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    disabledWhenNoRepository: s__(
      'ProjectSettings|This feature requires the repository to be enabled.',
    ),
    disabledWhenPrivate: s__(
      'ProjectSettings|Feature visibility cannot be changed while the project is private.',
    ),
  },
  model: {
    prop: 'value',
    event: 'change',
  },
  props: {
    id: {
      type: String,
      required: false,
      default: '',
    },
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
  },
  emits: ['change'],
  data() {
    return {
      valueWhenFeatureLastEnabled:
        this.isFeatureEnabled(this.value) || this.options.length === 0
          ? this.value
          : this.lastOptionValue(),
    };
  },
  computed: {
    internalValue: {
      get() {
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
        this.displayOptions.length < 2
      );
    },
    // Explains only the external causes the parent signals (repository off, project
    // private); a feature that is simply toggled off needs no tooltip.
    disabledReason() {
      if (this.disabledInput) {
        return this.$options.i18n.disabledWhenNoRepository;
      }

      if (this.disabledSelectInput) {
        return this.$options.i18n.disabledWhenPrivate;
      }

      return '';
    },
    valueWhenFeatureEnabled() {
      if (this.options.length === 0) {
        return this.valueWhenFeatureLastEnabled;
      }
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
    <div
      v-gl-tooltip="{ disabled: !disabledReason, title: disabledReason }"
      class="select-wrapper gl-grow gl-rounded-base focus:gl-focus"
      :tabindex="disabledReason ? 0 : null"
    >
      <select
        :id="id"
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
