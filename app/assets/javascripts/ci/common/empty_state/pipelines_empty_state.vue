<script>
import { GlEmptyState } from '@gitlab/ui';
import EMPTY_PIPELINE_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';

export default {
  name: 'PipelinesEmptyState',
  components: {
    GlEmptyState,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
  },
  EMPTY_PIPELINE_SVG,
};
</script>
<template>
  <gl-empty-state :svg-path="$options.EMPTY_PIPELINE_SVG" :title="title" :description="description">
    <template v-if="$scopedSlots.description" #description>
      <slot name="description"></slot>
    </template>
    <template v-if="$scopedSlots.actions" #actions>
      <slot name="actions"></slot>
    </template>
  </gl-empty-state>
</template>
