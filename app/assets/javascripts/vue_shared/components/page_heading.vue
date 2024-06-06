<script>
export default {
  props: {
    heading: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-flex-wrap gl-items-center gl-justify-between gl-gap-y-2 gl-gap-x-5 gl-mt-5 gl-mb-3"
  >
    <h1 class="gl-heading-1 !gl-m-0" data-testid="page-heading">
      {{ heading }}
    </h1>
    <div
      v-if="$scopedSlots.actions"
      class="gl-flex gl-items-center gl-gap-3"
      data-testid="page-heading-actions"
    >
      <slot name="actions"></slot>
    </div>
  </div>
</template>
