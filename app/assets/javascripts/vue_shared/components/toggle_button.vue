<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { s__ } from '../../locale';

const ICON_ON = 'status_success_borderless';
const ICON_OFF = 'status_failed_borderless';
const LABEL_ON = s__('ToggleButton|Toggle Status: ON');
const LABEL_OFF = s__('ToggleButton|Toggle Status: OFF');

export default {
  components: {
    GlIcon,
    GlLoadingIcon,
  },

  model: {
    prop: 'value',
    event: 'change',
  },

  props: {
    name: {
      type: String,
      required: false,
      default: null,
    },
    value: {
      type: Boolean,
      required: false,
      default: null,
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
  },

  computed: {
    toggleIcon() {
      return this.value ? ICON_ON : ICON_OFF;
    },
    ariaLabel() {
      return this.value ? LABEL_ON : LABEL_OFF;
    },
  },

  methods: {
    toggleFeature() {
      if (!this.disabledInput) this.$emit('change', !this.value);
    },
  },
};
</script>

<template>
  <label class="gl-mt-2">
    <input v-if="name" :name="name" :value="value" type="hidden" />
    <button
      type="button"
      role="switch"
      class="project-feature-toggle"
      :aria-label="ariaLabel"
      :aria-checked="value"
      :class="{
        'is-checked': value,
        'gl-blue-500': value,
        'is-disabled': disabledInput,
        'is-loading': isLoading,
      }"
      @click.prevent="toggleFeature"
    >
      <gl-loading-icon class="loading-icon" />
      <span class="toggle-icon">
        <gl-icon
          :size="18"
          :name="toggleIcon"
          :class="value ? 'gl-text-blue-500' : 'gl-text-gray-400'"
        />
      </span>
    </button>
  </label>
</template>
