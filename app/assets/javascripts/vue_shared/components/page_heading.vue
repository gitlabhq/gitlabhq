<script>
export default {
  props: {
    heading: {
      type: String,
      required: false,
      default: null,
    },
    inlineActions: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="gl-my-5 gl-flex gl-flex-wrap gl-items-center gl-justify-between gl-gap-y-3">
    <div
      class="gl-flex gl-w-full gl-flex-wrap gl-justify-between gl-gap-x-5 gl-gap-y-3 md:gl-flex-nowrap"
    >
      <h1 class="gl-heading-1 !gl-m-0" data-testid="page-heading">
        <slot name="heading"></slot>
        <template v-if="!$scopedSlots.heading">{{ heading }}</template>
      </h1>
      <div
        v-if="$scopedSlots.actions"
        class="page-heading-actions gl-flex gl-shrink-0 gl-flex-wrap gl-items-center gl-gap-3 md:gl-mt-1 lg:gl-mt-2"
        :class="{ 'gl-w-full sm:gl-w-auto': !inlineActions, 'gl-w-auto': inlineActions }"
        data-testid="page-heading-actions"
      >
        <slot name="actions"></slot>
      </div>
    </div>
    <div
      v-if="$scopedSlots.description"
      class="gl-w-full gl-text-subtle"
      data-testid="page-heading-description"
    >
      <slot name="description"></slot>
    </div>
  </div>
</template>
