<script>
  import loadingIcon from './loading_icon.vue';

  export default {
    props: {
      name: {
        type: String,
        required: false,
        default: '',
      },
      value: {
        type: Boolean,
        required: true,
      },
      disabledInput: {
        type: Boolean,
        required: false,
        default: false,
      },
      isLoading: {
        type: Boolean,
        required: false,
        default: false,
      },
      enabledText: {
        type: String,
        required: false,
        default: 'Enabled',
      },
      disabledText: {
        type: String,
        required: false,
        default: 'Disabled',
      },
    },

    components: {
      loadingIcon,
    },

    model: {
      prop: 'value',
      event: 'change',
    },

    methods: {
      toggleFeature() {
        if (!this.disabledInput) this.$emit('change', !this.value);
      },
    },
  };
</script>

<template>
  <label class="toggle-wrapper">
    <input
      type="hidden"
      :name="name"
      :value="value"
    />
    <button
      type="button"
      aria-label="Toggle"
      class="project-feature-toggle"
      :data-enabled-text="enabledText"
      :data-disabled-text="disabledText"
      :class="{
        'is-checked': value,
        'is-disabled': disabledInput,
        'is-loading': isLoading
      }"
      @click="toggleFeature"
    >
      <loadingIcon class="loading-icon" />
    </button>
  </label>
</template>
