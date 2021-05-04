<script>
import PipelineStatus from './pipeline_status.vue';
import ValidationSegment from './validation_segment.vue';

const baseClasses = ['gl-p-5', 'gl-bg-gray-10', 'gl-border-solid', 'gl-border-gray-100'];

const pipelineStatusClasses = [
  ...baseClasses,
  'gl-border-1',
  'gl-border-b-0!',
  'gl-rounded-top-base',
];

const validationSegmentClasses = [...baseClasses, 'gl-border-1', 'gl-rounded-base'];

const validationSegmentWithPipelineStatusClasses = [
  ...baseClasses,
  'gl-border-1',
  'gl-rounded-bottom-left-base',
  'gl-rounded-bottom-right-base',
];

export default {
  pipelineStatusClasses,
  validationSegmentClasses,
  validationSegmentWithPipelineStatusClasses,
  components: {
    PipelineStatus,
    ValidationSegment,
  },
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
    isNewCiConfigFile: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    showPipelineStatus() {
      return !this.isNewCiConfigFile;
    },
    // make sure corners are rounded correctly depending on if
    // pipeline status is rendered
    validationStyling() {
      return this.showPipelineStatus
        ? this.$options.validationSegmentWithPipelineStatusClasses
        : this.$options.validationSegmentClasses;
    },
  },
};
</script>
<template>
  <div class="gl-mb-5">
    <pipeline-status v-if="showPipelineStatus" :class="$options.pipelineStatusClasses" />
    <validation-segment :class="validationStyling" :ci-config="ciConfigData" />
  </div>
</template>
