<script>
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
      v-if="name"
      type="hidden"
      :name="name"
      :value="value"
    />
    <button
      type="button"
      aria-label="Toggle"
      class="project-feature-toggle"
      data-enabled-text="Enabled"
      data-disabled-text="Disabled"
      :class="{ checked: value, disabled: disabledInput }"
      @click="toggleFeature"
    />
  </label>
</template>
