<script>
export default {
  props: {
    heading: {
      type: String,
      required: false,
      default: '',
    },
    headingClasses: {
      type: String,
      required: false,
      default: null,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasHeading() {
      return this.$scopedSlots.heading || this.heading;
    },
    hasDescription() {
      return this.$scopedSlots.description || this.description;
    },
  },
};
</script>

<template>
  <section class="settings-section js-search-settings-section">
    <div v-if="hasHeading || hasDescription" class="settings-sticky-header">
      <div class="settings-sticky-header-inner">
        <h2
          v-if="hasHeading"
          class="gl-heading-2 !gl-mb-3"
          :class="headingClasses"
          data-testid="settings-section-heading"
        >
          <slot v-if="$scopedSlots.heading" name="heading"></slot>
          <template v-else>{{ heading }}</template>
        </h2>
        <p
          v-if="hasDescription"
          class="gl-mb-3 gl-text-subtle"
          data-testid="settings-section-description"
        >
          <slot v-if="$scopedSlots.description" name="description"></slot>
          <template v-else>{{ description }}</template>
        </p>
      </div>
    </div>
    <div class="gl-mt-3">
      <slot></slot>
    </div>
  </section>
</template>
