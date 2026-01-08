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
  computed: {
    timelineClasses() {
      if (!this.timelineLayout || this.isLastDiscussion) return '';
      return 'gl-relative before:gl-content-[""] before:gl-bg-strong before:gl-absolute before:gl-w-[2px] before:gl-left-[31px] before:gl-top-[15px] before:gl-h-full';
    },
  },
};
</script>

<template>
  <li class="gl-list-none gl-p-3 gl-px-5" :class="timelineClasses">
    <div v-if="timelineLayout" class="gl-flex gl-gap-3">
      <div class="gl-relative gl-z-2">
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
