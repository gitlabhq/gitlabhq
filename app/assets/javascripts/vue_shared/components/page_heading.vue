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
  <div>
    <div
      class="gl-my-5 gl-flex gl-flex-wrap gl-items-center gl-justify-between gl-gap-x-5 gl-gap-y-2"
    >
      <h1 class="gl-heading-1 !gl-m-0" data-testid="page-heading">
        <slot name="heading"></slot>
        <template v-if="!$scopedSlots.heading">{{ heading }}</template>
      </h1>
      <div
        v-if="$scopedSlots.actions"
        class="gl-flex gl-items-center gl-gap-3"
        data-testid="page-heading-actions"
      >
        <slot name="actions"></slot>
      </div>
      <div
        v-if="$scopedSlots.description"
        class="gl-mt-2 gl-w-full gl-text-secondary"
        data-testid="page-heading-description"
      >
        <slot name="description"></slot>
      </div>
    </div>
  </div>
</template>
