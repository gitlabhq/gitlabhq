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
    noBottomBorder: {
      type: Boolean,
      required: false,
      default: false,
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
  <section
    class="settings-section js-search-settings-section"
    :class="{ 'settings-section-no-bottom': noBottomBorder }"
    data-testid="settings-section"
  >
    <div
      v-if="hasHeading || hasDescription"
      class="settings-sticky-header"
      :class="{ 'gl-mb-4': !hasDescription }"
    >
      <h2
        v-if="hasHeading"
        class="gl-heading-2 gl-mb-0"
        :class="headingClasses"
        data-testid="settings-section-heading"
      >
        <slot v-if="$scopedSlots.heading" name="heading"></slot>
        <template v-else>{{ heading }}</template>
      </h2>
    </div>
    <div v-if="hasDescription" class="settings-sticky-header-description gl-mb-6">
      <p class="gl-mb-0 gl-text-subtle" data-testid="settings-section-description">
        <slot v-if="$scopedSlots.description" name="description"></slot>
        <template v-else>{{ description }}</template>
      </p>
    </div>
    <div class="gl-mt-3">
      <slot></slot>
    </div>
  </section>
</template>
