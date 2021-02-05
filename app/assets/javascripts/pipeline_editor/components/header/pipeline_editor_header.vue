<script>
import ValidationSegment from './validation_segment.vue';

export default {
  validationSegmentClasses:
    'gl-p-5 gl-bg-gray-10 gl-border-solid gl-border-1 gl-border-gray-100 gl-rounded-base',
  components: {
    ValidationSegment,
  },
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
    isCiConfigDataLoading: {
      type: Boolean,
      required: true,
    },
  },
};
</script>
<template>
  <div class="gl-mb-5">
    <validation-segment
      :class="$options.validationSegmentClasses"
      :loading="isCiConfigDataLoading"
      :ci-config="ciConfigData"
    />
  </div>
</template>
