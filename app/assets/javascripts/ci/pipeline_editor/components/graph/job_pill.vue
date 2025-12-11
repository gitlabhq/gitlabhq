<script>
import { s__, sprintf } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

export default {
  components: {
    TooltipOnTruncate,
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
  },
  emits: ['on-mouse-enter', 'on-mouse-leave'],
  computed: {
    id() {
      return `${this.jobName}-${this.pipelineId}`;
    },
    jobPillClasses() {
      return [
        { 'gl-opacity-3': this.isFadedOut },
        { 'gl-bg-strong gl-shadow-inner-1-gray-200': this.isHovered },
      ];
    },
    label() {
      return sprintf(s__('Pipelines|%{jobName} job'), { jobName: this.jobName });
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
      <button
        :id="id"
        class="gl-relative gl-z-1 gl-mb-3 gl-w-full gl-truncate gl-rounded-6 gl-border-none gl-bg-default gl-px-5 gl-py-3 gl-shadow-inner-1-gray-100 gl-duration-slow gl-ease-ease"
        :class="jobPillClasses"
        :aria-label="label"
        type="button"
        @focus="onMouseEnter"
        @blur="onMouseLeave"
        @mouseover="onMouseEnter"
        @mouseleave="onMouseLeave"
      >
        {{ jobName }}
      </button>
    </tooltip-on-truncate>
  </div>
</template>
