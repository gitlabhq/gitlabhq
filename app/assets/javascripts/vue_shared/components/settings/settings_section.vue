<script>
export default {
  props: {
    heading: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <section class="settings-section">
    <div class="settings-sticky-header">
      <div class="settings-sticky-header-inner">
        <h2 class="gl-heading-2 !gl-mb-2">
          <slot v-if="$scopedSlots.heading" name="heading"></slot>
          <template v-else>{{ heading }}</template>
        </h2>
        <p v-if="$scopedSlots.description || description" class="gl-text-secondary gl-mb-3">
          <slot v-if="$scopedSlots.description" name="description"></slot>
          <template v-else>{{ description }}</template>
        </p>
      </div>
    </div>
    <div>
      <slot></slot>
    </div>
  </section>
</template>
