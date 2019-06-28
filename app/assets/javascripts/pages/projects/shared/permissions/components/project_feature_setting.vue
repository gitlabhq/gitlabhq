<script>
import projectFeatureToggle from '~/vue_shared/components/toggle_button.vue';
import { featureAccessLevelNone } from '../constants';

export default {
  components: {
    projectFeatureToggle,
  },

  model: {
    prop: 'value',
    event: 'change',
  },

  props: {
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
  <div :data-for="name" class="project-feature-controls">
    <input v-if="name" :name="name" :value="value" type="hidden" />
    <project-feature-toggle
      :value="featureEnabled"
      :disabled-input="disabledInput"
      @change="toggleFeature"
    />
    <div class="select-wrapper">
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
      <i aria-hidden="true" class="fa fa-chevron-down"> </i>
    </div>
  </div>
</template>
