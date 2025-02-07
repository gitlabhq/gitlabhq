<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
/**
 * Renders a downstream pipeline dropdown for the pipeline mini graph.
 */
export default {
  name: 'DownstreamPipelineDropdown',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    pipelineTooltipText() {
      const name = this.pipeline?.name || this.pipeline?.project?.name || __('Downstream pipeline');
      const status = this.pipeline?.detailedStatus?.label || __('unknown');

      return `${name} - ${status}`;
    },
  },
};
</script>

<template>
  <ci-icon
    v-gl-tooltip.hover
    :title="pipelineTooltipText"
    :status="pipeline.detailedStatus"
    :show-tooltip="false"
  />
</template>
