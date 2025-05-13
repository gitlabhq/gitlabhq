<script>
export default {
  props: {
    heading: {
      type: String,
      required: false,
      default: '',
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
  <div class="gl-mt-5">
    <div v-if="hasHeading || hasDescription" class="gl-mb-5">
      <h3
        v-if="hasHeading"
        class="gl-heading-3 !gl-mb-3"
        data-testid="settings-sub-section-heading"
      >
        <slot v-if="$scopedSlots.heading" name="heading"></slot>
        <template v-else>{{ heading }}</template>
      </h3>
      <p
        v-if="hasDescription"
        class="gl-max-w-88 gl-text-subtle"
        data-testid="settings-sub-section-description"
      >
        <slot v-if="$scopedSlots.description" name="description"></slot>
        <template v-else>{{ description }}</template>
      </p>
    </div>
    <div class="gl-mt-3">
      <slot></slot>
    </div>
  </div>
</template>
