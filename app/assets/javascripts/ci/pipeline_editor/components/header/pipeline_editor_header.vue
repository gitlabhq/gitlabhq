<script>
import { GlCard } from '@gitlab/ui';
import PipelineStatus from './pipeline_status.vue';
import ValidationSegment from './validation_segment.vue';

export default {
  components: {
    GlCard,
    PipelineStatus,
    ValidationSegment,
  },
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
    commitSha: {
      type: String,
      required: false,
      default: '',
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
  },
};
</script>
<template>
  <gl-card header-class="gl-px-4">
    <template v-if="showPipelineStatus" #header>
      <pipeline-status :commit-sha="commitSha" v-on="$listeners" />
    </template>

    <validation-segment :ci-config="ciConfigData" />
  </gl-card>
</template>
