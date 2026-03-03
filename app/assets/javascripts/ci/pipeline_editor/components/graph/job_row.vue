<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'JobRow',
  components: {
    GlButton,
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
    jobRowClasses() {
      return [
        { 'gl-opacity-3': this.isFadedOut },
        { 'gl-bg-strong gl-shadow-inner-1-gray-200': this.isHovered },
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
  <div
    :id="id"
    class="gl-flex gl-items-center gl-justify-between gl-px-5 gl-py-2"
    :class="jobRowClasses"
    @focus="onMouseEnter"
    @blur="onMouseLeave"
    @mouseover="onMouseEnter"
    @mouseleave="onMouseLeave"
  >
    <span>{{ jobName }}</span>
    <gl-button class="gl-invisible" category="tertiary" icon="ellipsis_v" />
  </div>
</template>
