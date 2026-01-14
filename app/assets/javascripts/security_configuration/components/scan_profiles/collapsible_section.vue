<script>
import { GlButton, GlCollapse, GlIcon } from '@gitlab/ui';

export default {
  name: 'CollapsibleSection',
  components: {
    GlButton,
    GlIcon,
    GlCollapse,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    subtitle: {
      type: String,
      required: false,
      default: null,
    },
    defaultExpanded: {
      type: Boolean,
      required: false,
      default: true,
    },
  },

  data() {
    return {
      isExpanded: this.defaultExpanded,
    };
  },

  methods: {
    toggle() {
      this.isExpanded = !this.isExpanded;
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <gl-button variant="link" @click="toggle">
      <span class="gl-heading-4">{{ title }}</span>
      <gl-icon
        name="chevron-right"
        class="gl-float-right gl-transition-all"
        :class="{ 'gl-rotate-90': isExpanded }"
      />
    </gl-button>

    <gl-collapse v-model="isExpanded">
      <div class="gl-mt-3">
        <p v-if="subtitle" class="gl-font-sm gl-mb-5 gl-text-secondary">
          {{ subtitle }}
        </p>
        <slot></slot>
      </div>
    </gl-collapse>
  </div>
</template>
