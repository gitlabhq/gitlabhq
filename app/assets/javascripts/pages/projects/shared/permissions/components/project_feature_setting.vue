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
    showToggle: {
      type: Boolean,
      required: false,
      default: true,
    },
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
      return this.value !== 0;
    },

    displayOptions() {
      if (this.featureEnabled) {
        return this.options;
      }
      return [featureAccessLevelNone];
    },

    displaySelectInput() {
      return this.disabledInput || !this.featureEnabled || this.displayOptions.length < 2;
    },
  },
  methods: {
    toggleFeature(featureEnabled) {
      if (featureEnabled === false || this.options.length < 1) {
        this.$emit('change', 0);
      } else {
        const [firstOptionValue] = this.options[this.options.length - 1];
        this.$emit('change', firstOptionValue);
      }
    },
  },
};
</script>

<template>
  <div :data-for="name" class="project-feature-controls gl-mx-0 gl-mt-2 gl-flex">
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
        :disabled="displaySelectInput"
        class="form-control project-repo-select select-control"
      >
        <option
          v-for="[optionValue, optionName] in displayOptions"
          :key="optionValue"
          :value="optionValue"
        >
          {{ optionName }}
        </option>
      </select>
      <gl-icon name="chevron-down" class="gl-absolute gl-right-3 gl-top-3" variant="default" />
    </div>
  </div>
</template>
