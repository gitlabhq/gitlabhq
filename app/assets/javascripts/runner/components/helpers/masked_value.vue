<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isMasked: true,
    };
  },
  computed: {
    label() {
      if (this.isMasked) {
        return __('Click to reveal');
      }
      return __('Click to hide');
    },
    icon() {
      if (this.isMasked) {
        return 'eye';
      }
      return 'eye-slash';
    },
    displayedValue() {
      if (this.isMasked && this.value?.length) {
        return '*'.repeat(this.value.length);
      }
      return this.value;
    },
  },
  methods: {
    toggleMasked() {
      this.isMasked = !this.isMasked;
    },
  },
};
</script>
<template>
  <span
    >{{ displayedValue }}
    <gl-button
      :aria-label="label"
      :icon="icon"
      class="gl-text-body!"
      data-testid="toggle-masked"
      variant="link"
      @click="toggleMasked"
    />
  </span>
</template>
