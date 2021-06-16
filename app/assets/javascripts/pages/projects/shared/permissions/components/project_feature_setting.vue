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

    selectOption(e) {
      this.$emit('change', Number(e.target.value));
    },
  },
};
</script>

<template>
  <div
    :data-for="name"
    class="project-feature-controls gl-display-flex gl-align-items-center gl-my-3 gl-mx-0"
  >
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
    <div class="select-wrapper gl-flex-grow-1">
      <select
        :disabled="displaySelectInput"
        class="form-control project-repo-select select-control"
        @change="selectOption"
      >
        <option
          v-for="[optionValue, optionName] in displayOptions"
          :key="optionValue"
          :value="optionValue"
          :selected="optionValue === value"
        >
          {{ optionName }}
        </option>
      </select>
      <gl-icon name="chevron-down" class="gl-absolute gl-top-3 gl-right-3 gl-text-gray-500" />
    </div>
  </div>
</template>
