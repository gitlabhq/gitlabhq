<script>
export default {
  inject: {
    injectedHeadingTag: {
      from: 'panelHeadingTag',
      default: 'h1',
    },
  },
  props: {
    heading: {
      type: String,
      required: false,
      default: null,
    },
    headingTag: {
      type: String,
      required: false,
      default: null,
      validator: (value) => value === null || ['h1', 'h2'].includes(value),
    },
    inlineActions: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    computedHeadingTag() {
      return this.headingTag ?? this.injectedHeadingTag;
    },
  },
};
</script>

<template>
  <header class="gl-my-5 gl-flex gl-flex-wrap gl-items-center gl-justify-between gl-gap-y-3">
    <div
      class="gl-flex gl-w-full gl-flex-wrap gl-items-start gl-justify-between gl-gap-x-5 gl-gap-y-3 @md/panel:gl-flex-nowrap"
    >
      <slot name="heading-wrapper">
        <component :is="computedHeadingTag" class="gl-heading-1 !gl-m-0" data-testid="page-heading">
          <slot name="heading"></slot>
          <template v-if="!$scopedSlots.heading">{{ heading }}</template>
        </component>
      </slot>
      <div
        v-if="$scopedSlots.actions"
        class="page-heading-actions gl-flex gl-shrink-0 gl-flex-wrap gl-items-center gl-gap-3 @md/panel:gl-mt-1 @lg/panel:gl-mt-2"
        :class="{ 'gl-w-full @sm/panel:gl-w-auto': !inlineActions, 'gl-w-auto': inlineActions }"
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
  </header>
</template>
