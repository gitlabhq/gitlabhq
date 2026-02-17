<script>
export default {
  name: 'TimelineEntryItem',
  props: {
    timelineLayout: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLastDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <li class="gl-list-none">
    <div v-if="timelineLayout" class="gl-flex gl-gap-3">
      <div
        class="gl-relative gl-z-1 gl-w-7 gl-flex-none"
        :class="
          isLastDiscussion &&
          `before:gl-absolute before:gl-bottom-0 before:gl-left-[calc(50%-1px)] before:gl-top-[16px] before:gl-z-[-1] before:gl-w-[2px] before:gl-bg-default before:gl-content-['']`
        "
      >
        <slot name="avatar"></slot>
      </div>
      <div class="gl-min-w-0 gl-flex-1">
        <slot name="content"></slot>
      </div>
    </div>
    <div v-else>
      <slot name="content"></slot>
    </div>
  </li>
</template>
