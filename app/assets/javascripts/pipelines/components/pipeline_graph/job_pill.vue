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
    pipelineId: {
      type: Number,
      required: true,
    },
    isHovered: {
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
    id() {
      return `${this.jobName}-${this.pipelineId}`;
    },
    jobPillClasses() {
      return [
        { 'gl-opacity-3': this.isFadedOut },
        { 'gl-bg-gray-50 gl-inset-border-1-gray-200': this.isHovered },
      ];
    },
  },
  methods: {
    onMouseEnter() {
      this.$emit('on-mouse-enter', this.jobName);
    },
    onMouseLeave() {
      this.$emit('on-mouse-leave');
    },
  },
};
</script>
<template>
  <div class="gl-w-full">
    <tooltip-on-truncate :title="jobName" truncate-target="child" placement="top">
      <div
        :id="id"
        class="gl-bg-white gl-inset-border-1-gray-100 gl-text-center gl-text-truncate gl-rounded-6 gl-mb-3 gl-px-5 gl-py-3 gl-relative gl-z-index-1 gl-transition-duration-slow gl-transition-timing-function-ease"
        :class="jobPillClasses"
        @mouseover="onMouseEnter"
        @mouseleave="onMouseLeave"
      >
        {{ jobName }}
      </div>
    </tooltip-on-truncate>
  </div>
</template>
