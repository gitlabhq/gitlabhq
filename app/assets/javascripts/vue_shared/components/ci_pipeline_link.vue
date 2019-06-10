<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    href: {
      type: String,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: true,
    },
    pipelineIid: {
      type: Number,
      required: true,
    },
  },
};
</script>
<template>
  <gl-link v-gl-tooltip :href="href" :title="__('Pipeline ID (IID)')">
    <span class="pipeline-id">#{{ pipelineId }}</span>
    <span class="pipeline-iid">(#{{ pipelineIid }})</span>
  </gl-link>
</template>
