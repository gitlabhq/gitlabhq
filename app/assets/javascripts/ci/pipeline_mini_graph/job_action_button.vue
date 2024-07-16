<script>
import { GlButton, GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'JobActionButton',
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    jobId: {
      type: String,
      required: true,
    },
    jobAction: {
      type: Object,
      required: true,
    },
    jobName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      showConfirmationModal: false,
    };
  },
};
</script>

<template>
  <div>
    <gl-button
      v-gl-tooltip.viewport.right
      :title="jobAction.title"
      :aria-label="jobAction.title"
      :disabled="isLoading"
      class="gl-rounded-full! gl-p-0! gl-w-6 gl-h-6"
    >
      <gl-loading-icon v-if="isLoading" size="sm" class="gl-m-2" />
      <gl-icon v-else :name="jobAction.icon" :size="12" />
    </gl-button>
  </div>
</template>
