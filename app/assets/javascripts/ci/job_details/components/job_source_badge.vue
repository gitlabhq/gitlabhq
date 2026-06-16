<script>
import { GlBadge, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

const SOURCE_CONFIG = {
  scan_execution_policy: {
    variant: 'info',
    icon: 'shield',
    label: s__('Job|Security policy'),
    tooltip: s__('Job|This job was added by a scan execution policy'),
  },
  pipeline_execution_policy: {
    variant: 'info',
    icon: 'shield',
    label: s__('Job|Security policy'),
    tooltip: s__('Job|This job was added by a pipeline execution policy'),
  },
};

export default {
  name: 'JobSourceBadge',
  components: {
    GlBadge,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    source: {
      type: String,
      required: false,
      default: null,
    },
    compact: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    sourceConfig() {
      return SOURCE_CONFIG[this.source];
    },
  },
};
</script>

<template>
  <gl-badge
    v-if="sourceConfig"
    v-gl-tooltip.bottom
    :variant="sourceConfig.variant"
    :title="sourceConfig.tooltip"
    :icon="compact ? sourceConfig.icon : undefined"
    class="gl-ml-2"
    data-testid="job-source-badge"
  >
    <template v-if="!compact">
      <gl-icon :name="sourceConfig.icon" :size="12" class="gl-mr-1" />
      {{ sourceConfig.label }}
    </template>
  </gl-badge>
</template>
