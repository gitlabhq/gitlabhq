<script>
import tooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

export default {
  components: {
    tooltipOnTruncate,
  },
  props: {
    jobName: {
      type: String,
      required: true,
    },
    jobId: {
      type: String,
      required: true,
    },
    isHighlighted: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFadedOut: {
      type: Boolean,
      required: false,
      default: false,
    },
    handleMouseOver: {
      type: Function,
      required: false,
      default: () => {},
    },
    handleMouseLeave: {
      type: Function,
      required: false,
      default: () => {},
    },
  },
  computed: {
    jobPillClasses() {
      return [
        { 'gl-opacity-3': this.isFadedOut },
        this.isHighlighted ? 'gl-shadow-blue-200-x0-y0-b4-s2' : 'gl-inset-border-2-green-400',
      ];
    },
  },
  methods: {
    onMouseEnter() {
      this.$emit('on-mouse-enter', this.jobId);
    },
    onMouseLeave() {
      this.$emit('on-mouse-leave');
    },
  },
};
</script>
<template>
  <tooltip-on-truncate :title="jobName" truncate-target="child" placement="top">
    <div
      :id="jobId"
      class="gl-w-15 gl-bg-white gl-text-center gl-text-truncate gl-rounded-pill gl-mb-3 gl-px-5 gl-py-2 gl-relative gl-z-index-1 gl-transition-duration-slow gl-transition-timing-function-ease"
      :class="jobPillClasses"
      @mouseover="onMouseEnter"
      @mouseleave="onMouseLeave"
    >
      {{ jobName }}
    </div>
  </tooltip-on-truncate>
</template>
