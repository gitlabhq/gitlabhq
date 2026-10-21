<script>
export default {
  name: 'DuoReadinessSection',
  props: {
    title: {
      type: String,
      required: true,
    },
    subtitle: {
      type: String,
      required: false,
      default: '',
    },
    headingTag: {
      type: String,
      required: false,
      default: 'h2',
      validator: (value) => ['h2', 'h3', 'h4'].includes(value),
    },
    // Off for content that draws its own frame, such as a table or cards.
    bordered: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    frameClass() {
      return this.bordered ? 'gl-border gl-overflow-hidden gl-rounded-lg' : null;
    },
  },
};
</script>

<template>
  <section data-testid="readiness-section">
    <component :is="headingTag" class="gl-heading-4 gl-mb-1" data-testid="readiness-section-title">
      {{ title }}
    </component>
    <p v-if="subtitle" class="gl-mb-4 gl-text-subtle" data-testid="readiness-section-subtitle">
      {{ subtitle }}
    </p>
    <div :class="frameClass">
      <slot></slot>
    </div>
  </section>
</template>
