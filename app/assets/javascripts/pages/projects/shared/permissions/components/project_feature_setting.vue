<script>
  import projectFeatureToggle from '../../../../../vue_shared/components/toggle_button.vue';

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
        return [
          [0, 'Enable feature to choose access level'],
        ];
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
    class="project-feature-controls"
    :data-for="name"
  >
    <input
      v-if="name"
      type="hidden"
      :name="name"
      :value="value"
    />
    <project-feature-toggle
      :value="featureEnabled"
      @change="toggleFeature"
      :disabled-input="disabledInput"
    />
    <div class="select-wrapper">
      <select
        class="form-control project-repo-select select-control"
        @change="selectOption"
        :disabled="displaySelectInput"
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
      <i
        aria-hidden="true"
        class="fa fa-chevron-down"
      >
      </i>
    </div>
  </div>
</template>
